//
//  GROIncrementalStore.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 12/7/15.
//  Copyright (c) 2015 Andrew Shepard. All rights reserved.
//

import CoreData
import CloudKit

public let GRODidCreateRecordNotification = "GRODidCreateRecordNotification"

public let GRODataSourceKey = "GRODataSourceKey"
public let GROUseInMemoryStoreKey = "GROUseInMemoryStoreKey"
public let GROObjectIDKey = "GROObjectIDKey"
public let GRORecordNameKey = "GRORecordNameKey"
public let GROConfigurationKey = "GROConfigurationKey"

public enum GROIncrementalStoreError: ErrorProtocol {
    case unsupportedRequest
    case wrongRequestType
    case objectNotFound
    case objectIdNotFound
    case noRemoteIdentifier
    case noEntityName
    case fetchError(ErrorProtocol)
}

@objc(GROIncrementalStore)
public class GROIncrementalStore: NSIncrementalStore {
    
    internal typealias RegisteredObjectsMap = [String: NSManagedObjectID]
    internal typealias RegisteredEntitiesMap = [String: RegisteredObjectsMap]
    
    private let cache = NSMutableDictionary()
    private let backingObjectIDCache = Cache<NSString, NSManagedObjectID>()
    internal var registeredEntities: RegisteredEntitiesMap = [:]
    internal var registeredBackingEntities: RegisteredEntitiesMap = [:]
    
    internal let dataSource: CloudDataSource
    internal let operationQueue = OperationQueue()
    
    private var useInMemoryStores: Bool = false
    
    internal(set) var configuration: Configuration
    
    public class var storeType: String {
        return String(GROIncrementalStore)
    }
    
    public override class func initialize() {
        NSPersistentStoreCoordinator.registerStoreClass(self, forStoreType: storeType)
    }
    
    override init(persistentStoreCoordinator root: NSPersistentStoreCoordinator?, configurationName name: String?, at url: URL, options: [NSObject : AnyObject]?) {
        
        guard let configuration = options?[GROConfigurationKey] as? Configuration else {
            fatalError("missing configuration")
        }
        
        self.configuration = configuration
        
        self.dataSource = options?[GRODataSourceKey] as? CloudDataSource ?? GRODefaultDataSource(configuration: configuration)
        self.useInMemoryStores = options?[GROUseInMemoryStoreKey] as? Bool ?? false
        
        super.init(persistentStoreCoordinator: root, configurationName: name, at: url as URL, options: options)
        
        NotificationCenter.default().addObserver(self, selector: #selector(GROIncrementalStore.contextDidChange(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil)
        
        NotificationCenter.default().addObserver(self, selector: #selector(GROIncrementalStore.didCreateRecord(_:)), name: GRODidCreateRecordNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default().removeObserver(self)
    }
    
    lazy var backingPersistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.augmentedModel)
        
        let storeType = self.useInMemoryStores ? NSInMemoryStoreType : NSSQLiteStoreType
        let path = GROIncrementalStore.storeType + ".sqlite"
        let url = try! URL.applicationDocumentsDirectory.appendingPathComponent(path)
        let options = [NSMigratePersistentStoresAutomaticallyOption: NSNumber(value: true),
            NSInferMappingModelAutomaticallyOption: NSNumber(value: true)];
        
        do {
            try coordinator.addPersistentStore(ofType: storeType, configurationName: nil, at: url, options: options)
        } catch {
            fatalError("could not create psc: \(error)")
        }
        
        return coordinator
    }()
    
    lazy var backingContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.backingPersistentStoreCoordinator
        context.retainsRegisteredObjects = true
        return context
    }()
    
    var mainContext: NSManagedObjectContext? = nil
    
    lazy var augmentedModel: NSManagedObjectModel = {
        guard let model = self.persistentStoreCoordinator?.managedObjectModel else {
            fatalError("model not found")
        }
        
        return model.GROAugmentedModel
    }()
    
    // MARK: - NSIncrementalStore
    
    public override func loadMetadata() throws {
        let uuid = UUID().uuidString
        self.metadata = [NSStoreTypeKey: GROIncrementalStore.storeType, NSStoreUUIDKey: uuid]
    }
    
    public override func execute(_ request: NSPersistentStoreRequest, with context: NSManagedObjectContext?) throws -> AnyObject {
        
        assert(context != self.backingContext, "wrong context")
        
        if mainContext == nil || mainContext != context {
            self.mainContext = context
        }
        
        if request.requestType == .fetchRequestType {
            return try self.executeFetchRequest(request, with: context)
        }
        else if request.requestType == .saveRequestType {
            return try self.executeSaveChangesRequest(request, with: context)
        }
        
        throw GROIncrementalStoreError.unsupportedRequest
    }
    
    public override func newValuesForObject(with objectID: NSManagedObjectID, with context: NSManagedObjectContext) throws -> NSIncrementalStoreNode {
        guard let name = objectID.entity.name else { fatalError("missing entity name") }
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: name)
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.fetchLimit = 1
        fetchRequest.includesSubentities = false
        
        let referenceObj = self.referenceObject(for: objectID)
        let identifier = resourceIdentifier(referenceObj)
        
        let predicate = Predicate(format: "%K = %@", Attribute.ResourceIdentifier, identifier)
        fetchRequest.predicate = predicate
        
        var results: [AnyObject]? = nil
        let privateContext = self.backingContext
        privateContext.performAndWait {
            do {
                results = try privateContext.fetch(fetchRequest)
            } catch {
                fatalError("could not obtain new values: \(error)")
            }
        }
        
        let values = results?.last as? [String: AnyObject] ?? [:]
        let node = NSIncrementalStoreNode(objectID: objectID, withValues: values, version: 1)
        return node
    }
    
    public override func newValue(forRelationship relationship: NSRelationshipDescription, forObjectWith objectID: NSManagedObjectID, with context: NSManagedObjectContext?) throws -> AnyObject {
        
        let referenceObj = self.referenceObject(for: objectID)
        let identifier = resourceIdentifier(referenceObj)
        
        do {
            let backingObjID = try self.backingObjectID(for: objectID.entity, with: String(identifier))
            
            if backingObjID != nil {
                let backingObj = try self.backingContext.existingObject(with: backingObjID!)
                if let backingRelationshipObj = backingObj.value(forKeyPath: relationship.name) {
                    if relationship.isToMany {
                        var objectIDs: [NSManagedObjectID] = []
                        
                        let relatedObjs = backingRelationshipObj
                        guard let entity = relationship.destinationEntity else { fatalError("missing entity") }
                        
                        guard let identifierSet = relatedObjs.value(forKeyPath: Attribute.ResourceIdentifier) as? NSSet else { fatalError() }
                        
                        guard let identifiers = identifierSet.allObjects as? [String] else { fatalError() }
                        
                        for identifier in identifiers {
                            let objectID = try self.objectID(for: entity, with: identifier)
                            objectIDs.append(objectID)
                        }
                        
                        return objectIDs
                    }
                    else {
                        guard let relatedObj = backingRelationshipObj as? NSManagedObject else { fatalError() }
                        let identifier = relatedObj.GROResourceIdentifier
                        
                        guard let entity = relationship.destinationEntity else { fatalError("missing entity") }
                        
                        let objectID = try self.objectID(for: entity, with: identifier)
                        return objectID
                    }
                }
            }
        }
        catch { }
        
        if relationship.isToMany {
            return []
        }
        else {
            return NSNull()
        }
    }
    
    // MARK: - Notifications
    
    func contextDidChange(_ notification: Notification) {
        guard let context = notification.object as? NSManagedObjectContext else { return }
        let contextSaveInfo = (notification as NSNotification).userInfo ?? [:]
        
        if context == self.backingContext {
            guard let mergeContext = self.mainContext else { return }
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: contextSaveInfo, into: [mergeContext])
        }
        else if context == self.mainContext {
            let mergeContext = self.backingContext
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: contextSaveInfo, into: [mergeContext])
            
            self.backingContext.perform({
                self.backingContext.saveOrLogError()
            })
        }
    }
    
    func didCreateRecord(_ notification: Notification) {
        guard let objectID = (notification as NSNotification).userInfo?[GROObjectIDKey] as? NSManagedObjectID else { return }
        guard let identifier = (notification as NSNotification).userInfo?[GRORecordNameKey] as? String else { return }
        
        guard let name = objectID.entity.name else { return }
        
        var entities = self.registeredEntities[name] ?? [:]
        entities[identifier] = objectID
        self.registeredEntities[name] = entities
    }
    
    // MARK: - Private
    
    private func executeFetchRequest(_ request: NSPersistentStoreRequest!, with context: NSManagedObjectContext!) throws -> [AnyObject] {
        guard let fetchRequest = request as? NSFetchRequest<NSManagedObject> else { fatalError() }
        let backingContext = self.backingContext
        
        if fetchRequest.resultType == [] {
            
            context.perform {
                self.fetchRemoteObjects(fetchRequest, context: context)
            }
            
            let managedObjects = self.cachedObjects(for: fetchRequest, materializedIn: context)
            return managedObjects
        }
        else if fetchRequest.resultType == .countResultType ||
                fetchRequest.resultType == .dictionaryResultType ||
                fetchRequest.resultType == .managedObjectIDResultType {
            do {
                return try backingContext.fetch(fetchRequest)
            }
            catch { throw error }
        }

        return []
    }
    
    private func executeSaveChangesRequest(_ request: NSPersistentStoreRequest!, with context: NSManagedObjectContext!) throws -> [AnyObject] {
        
        guard let saveRequest = request as? NSSaveChangesRequest else {
            throw GROIncrementalStoreError.wrongRequestType
        }
        
        self.saveRemoteObjects(saveRequest, context: context)
        
        return []
    }
    
    private func cachedObjects(for request: NSFetchRequest<NSManagedObject>, materializedIn context: NSManagedObjectContext) -> [NSManagedObject] {
        
        guard let cacheFetchRequest = request.copy() as? NSFetchRequest<NSManagedObject> else { fatalError() }
        guard let entityName = request.entityName else { fatalError() }
        guard let entity = request.entity else { fatalError("missing entity") }
        
        let backingContext = self.backingContext
        cacheFetchRequest.entity = NSEntityDescription.entity(forEntityName: entityName, in: backingContext)
        cacheFetchRequest.resultType = []
        cacheFetchRequest.propertiesToFetch = [Attribute.ResourceIdentifier]
        
        var cachedObjects: [AnyObject] = []
        backingContext.performAndWait {
            do {
                cachedObjects = try backingContext.fetch(cacheFetchRequest)
            }
            catch {
                fatalError("error executing fetch request: \(error)")
            }
        }
        
        print("found \(cachedObjects.count) objects in backing store")
        
        let results = cachedObjects as NSArray
        let resourceIds = results.value(forKeyPath: Attribute.ResourceIdentifier) as? [NSString] ?? []
        
        var mainObjects: [NSManagedObject] = []
        context.performAndWait {
            mainObjects = resourceIds.map({ (resourceId: NSString) -> NSManagedObject in
                let objectId = try! self.objectID(for: entity, identifier: resourceId)
                let managedObject = context.object(with: objectId)
                guard let transformableObj = managedObject as? ManagedObjectTransformable else { fatalError() }
                
                let predicate = Predicate(format: "%K = %@", Attribute.ResourceIdentifier, resourceId)
                guard let backingObj = results.filtered(using: predicate).first as? NSManagedObject else { fatalError() }
                
                transformableObj.transform(object: backingObj)
                
                return managedObject
            })
        }
        
        print("materialized \(mainObjects.count) objects into main context")
        
        return mainObjects
    }
    
    private func fetchRemoteObjects(_ request: NSFetchRequest<NSManagedObject>, context: NSManagedObjectContext) {
        
        let verifyRecordZone = VerifyRecordZoneOperation(context: backingContext, dataSource: dataSource)
        let verifySubscriptions = VerifySubscriptionOperation(context: backingContext, dataSource: dataSource, configuration: configuration)
        
        let fetchChanges = FetchChangesOperation(request: request, context: context, backingContext: backingContext, dataSource: dataSource)
        let injestDeletedRecords = InjestDeletedRecordsOperation(operation: fetchChanges)
        let injestModifiedRecords = InjestModifiedRecordsOperation(operation: fetchChanges)
        
        fetchChanges.delegate = self
        injestDeletedRecords.delegate = self
        injestModifiedRecords.delegate = self
        
        injestDeletedRecords.addDependency(fetchChanges)
        injestModifiedRecords.addDependency(injestDeletedRecords)
        
        verifySubscriptions.addDependency(verifyRecordZone)
        fetchChanges.addDependency(verifySubscriptions)
        
        [injestDeletedRecords, injestModifiedRecords].onFinish {
            self.backingContext.performAndWait({
                self.backingContext.saveOrLogError()
            })
        }
        
        operationQueue.addOperation(verifyRecordZone)
        operationQueue.addOperation(verifySubscriptions)
        operationQueue.addOperation(fetchChanges)
        operationQueue.addOperation(injestDeletedRecords)
        operationQueue.addOperation(injestModifiedRecords)
    }
    
    private func saveRemoteObjects(_ request: NSSaveChangesRequest, context: NSManagedObjectContext) {
        
        let pushChanges = PushChangesOperation(request: request, context: context, backingContext: backingContext, dataSource: dataSource)
        let injestDeletedRecords = InjestDeletedRecordsOperation(operation: pushChanges)
        let injestModifiedRecords = InjestModifiedRecordsOperation(operation: pushChanges)
        
        injestDeletedRecords.delegate = self
        injestModifiedRecords.delegate = self
        
        injestDeletedRecords.addDependency(pushChanges)
        injestModifiedRecords.addDependency(injestDeletedRecords)
        
        [injestDeletedRecords, injestModifiedRecords].onFinish {
            self.backingContext.performAndWait({
                self.backingContext.saveOrLogError()
            })
        }
        
        operationQueue.addOperation(pushChanges)
        operationQueue.addOperation(injestDeletedRecords)
        operationQueue.addOperation(injestModifiedRecords)
    }
}

extension GROIncrementalStore: ManagedObjectIDProvider {
    
    
    
    func objectID(for entity: NSEntityDescription, identifier: NSString?) throws -> NSManagedObjectID {
        guard let identifier = identifier else { throw GROIncrementalStoreError.noRemoteIdentifier }
        guard let name = entity.name else { throw GROIncrementalStoreError.noEntityName }
        
        let cachedObjectIdentifier = Attribute.Prefix + String(identifier)
        
        var managedObjectId: NSManagedObjectID? = nil
        if let entities = self.registeredEntities[name] {
            if let objectId = entities[String(identifier)] {
                managedObjectId = objectId
            }
        }
        
        if managedObjectId == nil {
            guard let context = self.mainContext else { fatalError() }
            
            context.performAndWait {
                for object in context.registeredObjects {
                    let refObj = self.referenceObject(for: object.objectID)
                    if identifier == resourceIdentifier(refObj) {
                        managedObjectId = object.objectID
                        break
                    }
                }
            }
        }
        
        if managedObjectId == nil {
            managedObjectId = newObjectID(for: entity, referenceObject: cachedObjectIdentifier)
        }
        
        guard let _ = managedObjectId else { throw GROIncrementalStoreError.objectIdNotFound }
        
        var entities = self.registeredEntities[name] ?? [:]
        entities[String(identifier)] = managedObjectId!
        self.registeredEntities[name] = entities
        
        return managedObjectId!
    }
    
    func backingObjectID(for entity: NSEntityDescription, identifier: NSString?) throws -> NSManagedObjectID? {
        guard let identifier = identifier else { throw GROIncrementalStoreError.noRemoteIdentifier }
        guard let name = entity.name else { throw GROIncrementalStoreError.noEntityName }
        
        let fetchRequest = NSFetchRequest<NSManagedObjectID>(entityName: name)
        fetchRequest.resultType = .managedObjectIDResultType
        fetchRequest.fetchLimit = 1
        
        let predicate = Predicate(format: "%K = %@", Attribute.ResourceIdentifier, identifier)
        fetchRequest.predicate = predicate
        
        var backingObjectId: NSManagedObjectID?
        if let entities = self.registeredBackingEntities[name] {
            if let objectId = entities[String(identifier)] {
                backingObjectId = objectId
            }
        }
        
        if backingObjectId == nil {
            var fetchError: ErrorProtocol?
            
            self.backingContext.performAndWait {
                do {
                    let results = try self.backingContext.fetch(fetchRequest)
                    backingObjectId = results.last
                } catch (let error) {
                    fetchError = error
                }
            }
            
            guard fetchError == nil else { throw GROIncrementalStoreError.fetchError(fetchError!) }
            
            if backingObjectId != nil {
                var entities = self.registeredBackingEntities[name] ?? [:]
                entities[String(identifier)] = backingObjectId!
                self.registeredBackingEntities[name] = entities
            }
        }
        
        return backingObjectId
    }
    
    func entity(for identifier: String, context: NSManagedObjectContext) -> NSEntityDescription? {
        for (name, identifiers) in self.registeredEntities {
            for (id, _) in identifiers {
                if id == identifier {
                    let entity = NSEntityDescription.entity(forEntityName: name, in: context)
                    return entity
                }
            }
        }
        
        for (name, identifiers) in self.registeredBackingEntities {
            for (id, _) in identifiers {
                if id == identifier {
                    let entity = NSEntityDescription.entity(forEntityName: name, in: context)
                    return entity
                }
            }
        }
        
        fatalError("missing entity")
    }
    
    func register(_ objectID: NSManagedObjectID, for identifier: String, context: NSManagedObjectContext) {
        guard let name = objectID.entity.name else { return }
        
        if context == self.backingContext {
            var entities = self.registeredBackingEntities[name] ?? [:]
            entities[String(identifier)] = objectID
            self.registeredBackingEntities[name] = entities
        }
        else {
            var entities = self.registeredEntities[name] ?? [:]
            entities[String(identifier)] = objectID
            self.registeredEntities[name] = entities
        }
    }
}

private func resourceIdentifier(_ referenceObject: AnyObject) -> String {
    let refObj = String(referenceObject.description)
    let prefix = Attribute.Prefix
    
    if refObj.hasPrefix(prefix) {
        let index = refObj.index(refObj.startIndex, offsetBy: prefix.characters.count)
        let identifier = refObj.substring(from: index)
        return identifier
    }
    
    return refObj
}
