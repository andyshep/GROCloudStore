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

public enum GROIncrementalStoreError: Error {
    case unsupportedRequest
    case wrongRequestType
    case objectNotFound
    case objectIdNotFound
    case noRemoteIdentifier
    case noEntityName
    case fetchError(Error)
}

@objc(GROIncrementalStore)
public class GROIncrementalStore: NSIncrementalStore {
    
    internal typealias RegisteredObjectsMap = [String: NSManagedObjectID]
    internal typealias RegisteredEntitiesMap = [String: RegisteredObjectsMap]
    
    private let cache = NSMutableDictionary()
    private let backingObjectIDCache = NSCache<NSString, NSManagedObjectID>()
    internal var registeredEntities: RegisteredEntitiesMap = [:]
    internal var registeredBackingEntities: RegisteredEntitiesMap = [:]
    
    internal let dataSource: CloudDataSource
    internal let operationQueue = OperationQueue()
    
    private var useInMemoryStores: Bool = false
    
    internal(set) var configuration: Configuration
    
    public class var storeType: String {
        return String(describing: GROIncrementalStore.self)
    }
    
//    public override class func initialize() {
//        NSPersistentStoreCoordinator.registerStoreClass(self, forStoreType: storeType)
//    }
    
    override init(persistentStoreCoordinator root: NSPersistentStoreCoordinator?, configurationName name: String?, at url: URL, options: [AnyHashable : Any]? = nil) {
        guard let configuration = options?[GROConfigurationKey] as? Configuration else {
            fatalError("missing configuration")
        }
        
        self.configuration = configuration
        
        self.dataSource = options?[GRODataSourceKey] as? CloudDataSource ?? GRODefaultDataSource(configuration: configuration)
        self.useInMemoryStores = options?[GROUseInMemoryStoreKey] as? Bool ?? false
        
        super.init(persistentStoreCoordinator: root, configurationName: name, at: url, options: options)
        
        NotificationCenter.default.addObserver(self, selector: #selector(GROIncrementalStore.contextDidChange(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(GROIncrementalStore.didCreateRecord(_:)), name: NSNotification.Name(rawValue: GRODidCreateRecordNotification), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(GROIncrementalStore.cloudDidChange(_:)), name: NSNotification.Name.NSUbiquityIdentityDidChange, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    lazy var backingPersistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.augmentedModel)
        let identifier = uniqueStoreIdentifier()
        
        let storeType = self.useInMemoryStores ? NSInMemoryStoreType : NSSQLiteStoreType
        let path = identifier + ".sqlite"
        
        #if os(iOS)
        let url = URL.applicationDocumentsDirectory.appendingPathComponent(path)
        #endif
        
        #if os(macOS)
        let url = URL.applicationSupportDirectory.appendingPathComponent(path)
        #endif
        
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
        
        return model.augmentedModel
    }()
    
    public override func loadMetadata() throws {
        let uuid = UUID().uuidString
        self.metadata = [NSStoreTypeKey: GROIncrementalStore.storeType, NSStoreUUIDKey: uuid]
    }
    
    public override func execute(_ request: NSPersistentStoreRequest, with context: NSManagedObjectContext?) throws -> Any {
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
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: name)
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.fetchLimit = 1
        fetchRequest.includesSubentities = false
        
        let referenceObj = self.referenceObject(for: objectID)
        let identifier = resourceIdentifier(referenceObj as AnyObject)
        
        let predicate = NSPredicate(format: "%K = %@", GROAttribute.resourceIdentifier, identifier)
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
    
    public override func newValue(forRelationship relationship: NSRelationshipDescription, forObjectWith objectID: NSManagedObjectID, with context: NSManagedObjectContext?) throws -> Any {
        let referenceObj = self.referenceObject(for: objectID)
        let identifier = resourceIdentifier(referenceObj as AnyObject)
        
        do {
            let backingObjID = try self.backingObjectID(for: objectID.entity, with: String(identifier))
            
            if backingObjID != nil {
                let backingObj = try self.backingContext.existingObject(with: backingObjID!)
                if let backingRelationshipObj = backingObj.value(forKeyPath: relationship.name) {
                    if relationship.isToMany {
                        var objectIDs: [NSManagedObjectID] = []
                        
                        guard let relatedObjs = backingRelationshipObj as? NSObject else { fatalError() }
                        guard let entity = relationship.destinationEntity else { fatalError("missing entity") }
                        guard let identifierSet = relatedObjs.value(forKeyPath: GROAttribute.resourceIdentifier) as? NSSet else { fatalError() }
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
        catch {
            print("error obtaining new value for relationship: \(error)")
        }
        
        return relationship.isToMany ? [] : NSNull()
    }
}
