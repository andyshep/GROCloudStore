//
//  GROIncrementalStore+Private.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 6/16/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import Foundation

extension GROIncrementalStore {
    
    internal func executeFetchRequest(_ request: NSPersistentStoreRequest, with context: NSManagedObjectContext!) throws -> [AnyObject] {
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
    
    internal func executeSaveChangesRequest(_ request: NSPersistentStoreRequest, with context: NSManagedObjectContext!) throws -> [NSManagedObject] {
        
        self.saveRemoteObjects(for: request, in: context)
        
        return []
    }
    
    private func cachedObjects(for request: NSFetchRequest<NSManagedObject>, materializedIn context: NSManagedObjectContext) -> [NSManagedObject] {
        
        guard let cacheFetchRequest = request.copy() as? NSFetchRequest<NSManagedObject> else { fatalError() }
        guard let entityName = request.entityName else { fatalError() }
        guard let entity = request.entity else { fatalError("missing entity") }
        
        let backingContext = self.backingContext
        cacheFetchRequest.entity = NSEntityDescription.entity(forEntityName: entityName, in: backingContext)
        cacheFetchRequest.resultType = []
        cacheFetchRequest.propertiesToFetch = [GROAttribute.resourceIdentifier]
        
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
        let resourceIds = results.value(forKeyPath: GROAttribute.resourceIdentifier) as? [NSString] ?? []
        
        var mainObjects: [NSManagedObject] = []
        context.performAndWait {
            mainObjects = resourceIds.map({ (resourceId: NSString) -> NSManagedObject in
                let objectId = try! self.objectID(for: entity, with: resourceId)
                let managedObject = context.object(with: objectId)
                guard let transformableObj = managedObject as? ManagedObjectTransformable else { fatalError() }
                
                let predicate = NSPredicate(format: "%K = %@", GROAttribute.resourceIdentifier, resourceId)
                guard let backingObj = results.filtered(using: predicate).first as? NSManagedObject else { fatalError() }
                
                transformableObj.transform(using: backingObj)
                
                return managedObject
            })
        }
        
        print("materialized \(mainObjects.count) objects into main context")
        
        return mainObjects
    }
    
    private func fetchRemoteObjects(_ request: NSFetchRequest<NSManagedObject>, context: NSManagedObjectContext) {
        
        let verifyRecordZone = VerifyRecordZoneOperation(context: backingContext, dataSource: dataSource)
        let verifySubscriptions = VerifySubscriptionOperation(context: backingContext, dataSource: dataSource, configuration: configuration)
        
        // FIXME: do you need both database and zone changes operation?
        // what is the difference?
        let databaseChanges = DatabaseChangesOperation(context: backingContext, dataSource: dataSource)
        let recordZoneChanges = ZoneChangesOperation(operation: databaseChanges, request: request, context: context)
        
        let injestDeletedRecords = InjestDeletedRecordsOperation(operation: recordZoneChanges)
        let injestModifiedRecords = InjestModifiedRecordsOperation(operation: recordZoneChanges)
        
        recordZoneChanges.delegate = self
        injestDeletedRecords.delegate = self
        injestModifiedRecords.delegate = self
        
        recordZoneChanges.addDependency(databaseChanges)
        
        injestDeletedRecords.addDependency(recordZoneChanges)
        injestModifiedRecords.addDependency(injestDeletedRecords)
        
        verifySubscriptions.addDependency(verifyRecordZone)
        recordZoneChanges.addDependency(verifySubscriptions)
        
        [injestDeletedRecords, injestModifiedRecords].onFinish {
            self.backingContext.performAndWait({
                self.backingContext.saveOrLogError()
            })
        }
        
        operationQueue.addOperation(verifyRecordZone)
        operationQueue.addOperation(verifySubscriptions)
        operationQueue.addOperation(databaseChanges)
        operationQueue.addOperation(recordZoneChanges)
        operationQueue.addOperation(injestDeletedRecords)
        operationQueue.addOperation(injestModifiedRecords)
    }
    
    private func saveRemoteObjects(for request: NSPersistentStoreRequest, in context: NSManagedObjectContext) {
        guard let saveRequest = request as? NSSaveChangesRequest else {
//            throw GROIncrementalStoreError.wrongRequestType
            fatalError()
        }
        
        let pushChanges = PushChangesOperation(request: saveRequest, context: context, backingContext: backingContext, dataSource: dataSource)
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
    
    private func checkCloudKitAccountStatus(completion: @escaping (_ status: CKAccountStatus) -> ()) {
        let accountStatus = AccountStatusOperation(dataSource: dataSource)
        
        accountStatus.completionBlock = {
            if let status = accountStatus.status {
                completion(status)
            } else {
                completion(.couldNotDetermine)
            }
        }
        
        operationQueue.addOperation(accountStatus)
    }
    
    private func withValidCloudKitAccount(execute block: @escaping () -> ()) {
        checkCloudKitAccountStatus { (status) in
            if status == CKAccountStatus.available {
                block()
            }
            else {
                DispatchQueue.main.async {
                    let name = NSNotification.Name.GROCloudKitNotAvailable
                    NotificationCenter.default.post(name: name, object: nil)
                }
            }
        }
    }
}
