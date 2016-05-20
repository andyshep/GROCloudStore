//
//  GRODefaultDataSource.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 3/15/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import Foundation
import CloudKit

public class GRODefaultDataSource: GROCloudDataSource {
    
    public var configuration: Configuration
    
    init(configuration: Configuration) {
        self.configuration = configuration
    }
    
    public var database: CKDatabase {
        return self.container.privateCloudDatabase
    }
    
    public var container: CKContainer {
        return CKContainer(identifier: self.configuration.CloudContainer.Identifier)
    }

    
    // MARK: - Records
    
    public func saveRecord(record:CKRecord, completion: RecordCompletion) {
        database.saveRecord(record, completionHandler: completion)
    }
    
    public func recordWithID(recordID:CKRecordID, completion: RecordCompletion) {
        database.fetchRecordWithID(recordID, completionHandler: completion)
    }
    
    public func recordsOfType(type: String, completion: RecordsCompletion) {
        let query = CKQuery(recordType: type, predicate: NSPredicate(value: true))
        database.performQuery(query, inZoneWithID: nil, completionHandler: completion)
    }
    
    public func recordsOfType(type: String, fetched: RecordFetched, completion: QueryCompletion?) {
        let query = CKQuery(recordType: type, predicate: NSPredicate(value: true))
        let operation = CKQueryOperation(query: query)
        
        operation.recordFetchedBlock = {(record: CKRecord) in
            fetched(record)
        }
        
        operation.queryCompletionBlock = {(cursor: CKQueryCursor?, error: NSError?) in
            if let completion = completion {
                completion(cursor, error)
            }
        }
        
        database.addOperation(operation)
    }
    
    public func changedRecordsOfType(type: String, token: CKServerChangeToken?, completion: ChangedRecordHandler) {
        
        let name = self.configuration.CloudContainer.CustomZoneName
        let zoneId = CKRecordZoneID(zoneName: name, ownerName: CKOwnerDefaultName)
        let operation = CKFetchRecordChangesOperation(recordZoneID: zoneId, previousServerChangeToken: token)
        
        var changedRecords: [CKRecord] = []
        operation.recordChangedBlock = { (record: CKRecord) in
            changedRecords.append(record)
        }
        
        var deletedRecordIDs: [CKRecordID] = []
        operation.recordWithIDWasDeletedBlock = { (recordID: CKRecordID) in
            deletedRecordIDs.append(recordID)
        }
        
        operation.fetchRecordChangesCompletionBlock = { (token: CKServerChangeToken?, data: NSData?, error: NSError?) in
            
            if let error = error {
                print("ignoring error fetching changes: \(error)")
            }
            
            // FIXME: handle error
            // use changeset to represent these three params; tuple.
            
            completion(changed: changedRecords, deleted: deletedRecordIDs, token: token)
        }
        
        database.addOperation(operation)
    }
    
    public func deleteRecordWithID(recordID: CKRecordID, completion: DeleteRecordCompletion) {
        database.deleteRecordWithID(recordID, completionHandler: completion)
    }
    
    // MARK: - Subscriptions
    
    public func verifySubscriptions(completion: FetchSubscriptionsCompletion) {
        database.fetchAllSubscriptionsWithCompletionHandler(completion)
    }
    
    public func createSubscriptions(subscriptions: [CKSubscription], completion: CreateSubscriptionsCompletion) {
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: subscriptions, subscriptionIDsToDelete: nil)
        
        operation.modifySubscriptionsCompletionBlock = { (subscription: [CKSubscription]?, identifier: [String]?, error: NSError?) -> Void in
            completion(subscription?.first, error)
        }
        
        database.addOperation(operation)
    }
    
    // MARK: - Record Zones
    
    public func fetchRecordsZones(completion: FetchRecordZonesCompletion) -> Void {
        let operation = CKFetchRecordZonesOperation.fetchAllRecordZonesOperation()
        
        //        operation.qualityOfService = NSQualityOfService.UserInitiated
        
        operation.fetchRecordZonesCompletionBlock = {(zones, error) in
            completion(zones, error)
        }
        
        database.addOperation(operation)
    }
    
    public func createRecordZone(name: String, completion: CreateRecordZoneCompletion) -> Void {
        let zoneId = CKRecordZoneID(zoneName: name, ownerName: CKOwnerDefaultName)
        let zone = CKRecordZone(zoneID: zoneId)
        
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: [zone], recordZoneIDsToDelete: nil)
        
        operation.modifyRecordZonesCompletionBlock = {(zones, zoneIds, error) in
            completion(zones?.first, error)
        }
        
        database.addOperation(operation)
    }
}
