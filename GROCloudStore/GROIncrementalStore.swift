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

public enum GROIncrementalStoreError: ErrorType {
    case UnsupportedRequest
    case WrongRequestType
    case ObjectNotFound
    case ObjectIdNotFound
    case NoRemoteIdentifier
    case NoEntityName
    case FetchError(ErrorType)
}

@objc(GROIncrementalStore)
public class GROIncrementalStore: NSIncrementalStore {
    
    private typealias RegisteredObjectsMap = [String: NSManagedObjectID]
    private typealias RegisteredEntitiesMap = [String: RegisteredObjectsMap]
    
    private let cache = NSMutableDictionary()
    private let backingObjectIDCache = NSCache()
    private var registeredEntities: RegisteredEntitiesMap = [:]
    private var registeredBackingEntities: RegisteredEntitiesMap = [:]
    
    private let dataSource: GROCloudDataSource
    private let operationQueue = NSOperationQueue()
    
    private var useInMemoryStores: Bool = false
    
    private(set) var configuration: Configuration
    
    public class var storeType: String {
        return String(GROIncrementalStore)
    }
    
    public override class func initialize() {
        NSPersistentStoreCoordinator.registerStoreClass(self, forStoreType: storeType)
    }
    
    override init(persistentStoreCoordinator root: NSPersistentStoreCoordinator?, configurationName name: String?, URL url: NSURL, options: [NSObject : AnyObject]?) {
        
        guard let configuration = options?[GROConfigurationKey] as? Configuration else {
            fatalError("missing configuration")
        }
        
        self.configuration = configuration
        
        self.dataSource = options?[GRODataSourceKey] as? GROCloudDataSource ?? GRODefaultDataSource(configuration: configuration)
        self.useInMemoryStores = options?[GROUseInMemoryStoreKey] as? Bool ?? false
        
        super.init(persistentStoreCoordinator: root, configurationName: name, URL: url, options: options)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GROIncrementalStore.contextDidChange(_:)), name: NSManagedObjectContextDidSaveNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GROIncrementalStore.didCreateRecord(_:)), name: GRODidCreateRecordNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    lazy var backingPersistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.augmentedModel)
        
        let storeType = self.useInMemoryStores ? NSInMemoryStoreType : NSSQLiteStoreType
        let path = GROIncrementalStore.storeType + ".sqlite"
        let url = NSURL.applicationDocumentsDirectory().URLByAppendingPathComponent(path)
        let options = [NSMigratePersistentStoresAutomaticallyOption: NSNumber(bool: true),
            NSInferMappingModelAutomaticallyOption: NSNumber(bool: true)];
        
        do {
            try coordinator.addPersistentStoreWithType(storeType, configuration: nil, URL: url, options: options)
        } catch {
            fatalError("could not create psc: \(error)")
        }
        
        return coordinator
    }()
    
    lazy var backingContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
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
        let uuid = NSUUID().UUIDString
        self.metadata = [NSStoreTypeKey: GROIncrementalStore.storeType, NSStoreUUIDKey: uuid]
    }
    
    public override func executeRequest(request: NSPersistentStoreRequest, withContext context: NSManagedObjectContext?) throws -> AnyObject {
        
        assert(context != self.backingContext, "wrong context")
        
        if mainContext == nil || mainContext != context {
            self.mainContext = context
        }
        
        if request.requestType == .FetchRequestType {
            return try self.executeFetchRequest(request, withContext: context)
        }
        else if request.requestType == .SaveRequestType {
            return try self.executeSaveChangesRequest(request, withContext: context)
        }
        
        throw GROIncrementalStoreError.UnsupportedRequest
    }
    
    public override func newValuesForObjectWithID(objectID: NSManagedObjectID, withContext context: NSManagedObjectContext) throws -> NSIncrementalStoreNode {
        guard let name = objectID.entity.name else { fatalError("missing entity name") }
        let fetchRequest = NSFetchRequest(entityName: name)
        fetchRequest.resultType = .DictionaryResultType
        fetchRequest.fetchLimit = 1
        fetchRequest.includesSubentities = false
        
        let referenceObj = self.referenceObjectForObjectID(objectID)
        let identifier = resourceIdentifier(referenceObj)
        
        let predicate = NSPredicate(format: "%K = %@", Attribute.ResourceIdentifier, identifier)
        fetchRequest.predicate = predicate
        
        var results: [AnyObject]? = nil
        let privateContext = self.backingContext
        privateContext.performBlockAndWait {
            do {
                results = try privateContext.executeFetchRequest(fetchRequest)
            } catch {
                fatalError("could not obtain new values: \(error)")
            }
        }
        
        let values = results?.last as? [String: AnyObject] ?? [:]
        let node = NSIncrementalStoreNode(objectID: objectID, withValues: values, version: 1)
        return node
    }
    
    public override func newValueForRelationship(relationship: NSRelationshipDescription, forObjectWithID objectID: NSManagedObjectID, withContext context: NSManagedObjectContext?) throws -> AnyObject {
        
        let referenceObj = self.referenceObjectForObjectID(objectID)
        let identifier = resourceIdentifier(referenceObj)
        
        do {
            let backingObjID = try self.backingObjectIDForEntity(objectID.entity, identifier: String(identifier))
            
            if backingObjID != nil {
                let backingObj = try self.backingContext.existingObjectWithID(backingObjID!)
                if let backingRelationshipObj = backingObj.valueForKeyPath(relationship.name) {
                    if relationship.toMany {
                        var objectIDs: [NSManagedObjectID] = []
                        
                        let relatedObjs = backingRelationshipObj
                        guard let entity = relationship.destinationEntity else { fatalError("missing entity") }
                        
                        guard let identifierSet = relatedObjs.valueForKeyPath(Attribute.ResourceIdentifier) as? NSSet else { fatalError() }
                        guard let identifiers = identifierSet.allObjects as? [String] else { fatalError() }
                        
                        for id in identifiers {
                            let objectID = try self.objectIDForEntity(entity, identifier: id)
                            objectIDs.append(objectID)
                        }
                        
                        return objectIDs
                    }
                    else {
                        guard let relatedObj = backingRelationshipObj as? NSManagedObject else { fatalError() }
                        let identifier = relatedObj.GROResourceIdentifier
                        
                        guard let entity = relationship.destinationEntity else { fatalError("missing entity") }
                        
                        let objectID = try self.objectIDForEntity(entity, identifier: identifier)
                        return objectID
                    }
                }
            }
        }
        catch { }
        
        if relationship.toMany {
            return []
        }
        else {
            return NSNull()
        }
    }
    
    // MARK: - Notifications
    
    func contextDidChange(notification: NSNotification) {
        guard let context = notification.object as? NSManagedObjectContext else { return }
        let contextSaveInfo = notification.userInfo ?? [:]
        
        if context == self.backingContext {
            guard let mergeContext = self.mainContext else { return }
            NSManagedObjectContext.mergeChangesFromRemoteContextSave(contextSaveInfo, intoContexts: [mergeContext])
        }
        else if context == self.mainContext {
            let mergeContext = self.backingContext
            NSManagedObjectContext.mergeChangesFromRemoteContextSave(contextSaveInfo, intoContexts: [mergeContext])
            
            self.backingContext.performBlock({
                self.backingContext.saveOrLogError()
            })
        }
    }
    
    func didCreateRecord(notification: NSNotification) {
        guard let objectID = notification.userInfo?[GROObjectIDKey] as? NSManagedObjectID else { return }
        guard let identifier = notification.userInfo?[GRORecordNameKey] as? String else { return }
        
        guard let name = objectID.entity.name else { return }
        
        var entities = self.registeredEntities[name] ?? [:]
        entities[identifier] = objectID
        self.registeredEntities[name] = entities
    }
    
    // MARK: - Private
    
    private func executeFetchRequest(request: NSPersistentStoreRequest!, withContext context: NSManagedObjectContext!) throws -> [AnyObject] {
        guard let fetchRequest = request as? NSFetchRequest else { fatalError() }
        let backingContext = self.backingContext
        
        if fetchRequest.resultType == .ManagedObjectResultType {
            
            context.performBlock {
                self.fetchRemoteObjects(fetchRequest, context: context)
            }
            
            let managedObjects = self.cachedObjectsForRequest(fetchRequest, materializedInContext: context)
            return managedObjects
        }
        else if fetchRequest.resultType == .CountResultType ||
                fetchRequest.resultType == .DictionaryResultType ||
                fetchRequest.resultType == .ManagedObjectIDResultType {
            do {
                return try backingContext.executeFetchRequest(fetchRequest)
            }
            catch { throw error }
        }

        return []
    }
    
    private func executeSaveChangesRequest(request: NSPersistentStoreRequest!, withContext context: NSManagedObjectContext!) throws -> [AnyObject] {
        
        guard let saveRequest = request as? NSSaveChangesRequest else {
            throw GROIncrementalStoreError.WrongRequestType
        }
        
        self.saveRemoteObjects(saveRequest, context: context)
        
        return []
    }
    
    private func cachedObjectsForRequest(request: NSFetchRequest, materializedInContext context: NSManagedObjectContext) -> [NSManagedObject] {
        guard let cacheFetchRequest = request.copy() as? NSFetchRequest else { fatalError() }
        guard let entityName = request.entityName else { fatalError() }
        guard let entity = request.entity else { fatalError("missing entity") }
        
        let backingContext = self.backingContext
        cacheFetchRequest.entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: backingContext)
        cacheFetchRequest.resultType = .ManagedObjectResultType
        cacheFetchRequest.propertiesToFetch = [Attribute.ResourceIdentifier]
        
        var cachedObjects: [AnyObject] = []
        backingContext.performBlockAndWait {
            do {
                cachedObjects = try backingContext.executeFetchRequest(cacheFetchRequest)
            }
            catch {
                fatalError("error executing fetch request: \(error)")
            }
        }
        
        print("found \(cachedObjects.count) objects in backing store")
        
        let results = cachedObjects as NSArray
        let resourceIds = results.valueForKeyPath(Attribute.ResourceIdentifier) as? [NSString] ?? []
        
        var mainObjects: [NSManagedObject] = []
        context.performBlockAndWait { 
            mainObjects = resourceIds.map({ (resourceId: NSString) -> NSManagedObject in
                let objectId = try! self.objectIDForEntity(entity, identifier: resourceId)
                let managedObject = context.objectWithID(objectId)
                guard let transformableObj = managedObject as? ManagedObjectTransformable else { fatalError() }
                
                let predicate = NSPredicate(format: "%K = %@", Attribute.ResourceIdentifier, resourceId)
                guard let backingObj = results.filteredArrayUsingPredicate(predicate).first as? NSManagedObject else { fatalError() }
                
                transformableObj.transform(object: backingObj)
                
                return managedObject
            })
        }
        
        print("materialized \(mainObjects.count) objects into main context")
        
        return mainObjects
    }
    
    private func fetchRemoteObjects(request: NSFetchRequest, context: NSManagedObjectContext) {
        
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
            self.backingContext.performBlockAndWait({
                self.backingContext.saveOrLogError()
            })
        }
        
        operationQueue.addOperation(verifyRecordZone)
        operationQueue.addOperation(verifySubscriptions)
        operationQueue.addOperation(fetchChanges)
        operationQueue.addOperation(injestDeletedRecords)
        operationQueue.addOperation(injestModifiedRecords)
    }
    
    private func saveRemoteObjects(request: NSSaveChangesRequest, context: NSManagedObjectContext) {
        
        let pushChanges = PushChangesOperation(request: request, context: context, backingContext: backingContext, dataSource: dataSource)
        let injestDeletedRecords = InjestDeletedRecordsOperation(operation: pushChanges)
        let injestModifiedRecords = InjestModifiedRecordsOperation(operation: pushChanges)
        
        injestDeletedRecords.delegate = self
        injestModifiedRecords.delegate = self
        
        injestDeletedRecords.addDependency(pushChanges)
        injestModifiedRecords.addDependency(injestDeletedRecords)
        
        [injestDeletedRecords, injestModifiedRecords].onFinish {
            self.backingContext.performBlockAndWait({
                self.backingContext.saveOrLogError()
            })
        }
        
        operationQueue.addOperation(pushChanges)
        operationQueue.addOperation(injestDeletedRecords)
        operationQueue.addOperation(injestModifiedRecords)
    }
}

extension GROIncrementalStore: ManagedObjectIDProvider {
    
    func objectIDForEntity(entity: NSEntityDescription, identifier: NSString?) throws -> NSManagedObjectID {
        guard let identifier = identifier else { throw GROIncrementalStoreError.NoRemoteIdentifier }
        guard let name = entity.name else { throw GROIncrementalStoreError.NoEntityName }
        
        let cachedObjectIdentifier = Attribute.Prefix + String(identifier)
        
        var managedObjectId: NSManagedObjectID? = nil
        if let entities = self.registeredEntities[name] {
            if let objectId = entities[String(identifier)] {
                managedObjectId = objectId
            }
        }
        
        if managedObjectId == nil {
            guard let context = self.mainContext else { fatalError() }
            
            context.performBlockAndWait {
                for object in context.registeredObjects {
                    let refObj = self.referenceObjectForObjectID(object.objectID)
                    if identifier == resourceIdentifier(refObj) {
                        managedObjectId = object.objectID
                        break
                    }
                }
            }
        }
        
        if managedObjectId == nil {
            managedObjectId = newObjectIDForEntity(entity, referenceObject: cachedObjectIdentifier)
        }
        
        guard let _ = managedObjectId else { throw GROIncrementalStoreError.ObjectIdNotFound }
        
        var entities = self.registeredEntities[name] ?? [:]
        entities[String(identifier)] = managedObjectId!
        self.registeredEntities[name] = entities
        
        return managedObjectId!
    }
    
    func backingObjectIDForEntity(entity: NSEntityDescription, identifier: NSString?) throws -> NSManagedObjectID? {
        guard let identifier = identifier else { throw GROIncrementalStoreError.NoRemoteIdentifier }
        guard let name = entity.name else { throw GROIncrementalStoreError.NoEntityName }
        
        let fetchRequest = NSFetchRequest(entityName: name)
        fetchRequest.resultType = NSFetchRequestResultType.ManagedObjectIDResultType
        fetchRequest.fetchLimit = 1
        
        let predicate = NSPredicate(format: "%K = %@", Attribute.ResourceIdentifier, identifier)
        fetchRequest.predicate = predicate
        
        var backingObjectId: NSManagedObjectID?
        if let entities = self.registeredBackingEntities[name] {
            if let objectId = entities[String(identifier)] {
                backingObjectId = objectId
            }
        }
        
        if backingObjectId == nil {
            var fetchError: ErrorType?
            
            self.backingContext.performBlockAndWait {
                do {
                    let results = try self.backingContext.executeFetchRequest(fetchRequest)
                    backingObjectId = results.last as? NSManagedObjectID
                } catch (let error) {
                    fetchError = error
                }
            }
            
            guard fetchError == nil else { throw GROIncrementalStoreError.FetchError(fetchError!) }
            
            if backingObjectId != nil {
                var entities = self.registeredBackingEntities[name] ?? [:]
                entities[String(identifier)] = backingObjectId!
                self.registeredBackingEntities[name] = entities
            }
        }
        
        return backingObjectId
    }
    
    func entityForIdentifier(identifier: String, context: NSManagedObjectContext) -> NSEntityDescription? {
        for (name, identifiers) in self.registeredEntities {
            for (id, _) in identifiers {
                if id == identifier {
                    let entity = NSEntityDescription.entityForName(name, inManagedObjectContext: context)
                    return entity
                }
            }
        }
        
        for (name, identifiers) in self.registeredBackingEntities {
            for (id, _) in identifiers {
                if id == identifier {
                    let entity = NSEntityDescription.entityForName(name, inManagedObjectContext: context)
                    return entity
                }
            }
        }
        
        fatalError("missing entity")
    }
    
    func registerObjectID(objectID: NSManagedObjectID, forIdentifier identifier: String, context: NSManagedObjectContext) {
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

private func resourceIdentifier(referenceObject: AnyObject) -> String {
    let refObj = String(referenceObject.description)
    let prefix = Attribute.Prefix
    
    if refObj.hasPrefix(prefix) {
        let index = refObj.startIndex.advancedBy(prefix.characters.count)
        let identifier = refObj.substringFromIndex(index)
        return identifier
    }
    
    return refObj
}