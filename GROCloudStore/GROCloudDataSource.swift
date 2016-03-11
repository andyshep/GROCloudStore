//
//  GROCloudDataSource.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 7/11/15.
//  Copyright © 2015 Andrew Shepard. All rights reserved.
//

import Foundation
import CloudKit

typealias RecordsCompletion = ([CKRecord]?, NSError?) -> Void
typealias RecordCompletion = (CKRecord?, NSError?) -> Void
typealias DeleteRecordCompletion = (CKRecordID?, NSError?) -> Void

typealias FetchSubscriptionsCompletion = ([CKSubscription]?, NSError?) -> Void
typealias CreateSubscriptionsCompletion = (CKSubscription?, NSError?) -> Void

typealias RecordFetched = (CKRecord) -> Void
typealias QueryCompletion = (CKQueryCursor?, NSError?) -> Void

typealias FetchRecordZonesCompletion = ([CKRecordZoneID: CKRecordZone]?, NSError?) -> Void
typealias CreateRecordZoneCompletion = (CKRecordZone?, NSError?) -> Void

typealias ChangedRecordHandler = (changed: [CKRecord], deleted: [CKRecordID], token: CKServerChangeToken?) -> Void

class GROCloudDataSource: NSObject {
    lazy var container: CKContainer = {
        return CKContainer(identifier: CloudContainer.Identifier)
    }()
    
    lazy var publicDatabase: CKDatabase = {
        return self.container.publicCloudDatabase
    }()
    
    lazy var privateDatabase: CKDatabase = {
        return self.container.privateCloudDatabase
    }()
    
    // MARK: - Records
    
    func saveRecord(record:CKRecord, completion: RecordCompletion) {
        privateDatabase.saveRecord(record, completionHandler: completion)
    }
    
    func recordWithID(recordID:CKRecordID, completion: RecordCompletion) {
        privateDatabase.fetchRecordWithID(recordID, completionHandler: completion)
    }
    
    func recordsOfType(type: String, completion: RecordsCompletion) {
        let query = CKQuery(recordType: type, predicate: NSPredicate(value: true))
        privateDatabase.performQuery(query, inZoneWithID: nil, completionHandler: completion)
    }
    
    func recordsOfType(type: String, fetched: RecordFetched, completion: QueryCompletion?) {
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
        
        privateDatabase.addOperation(operation)
    }
    
    func changedRecordsOfType(type: String, token: CKServerChangeToken?, completion: ChangedRecordHandler) {
        
        let zoneId = CKRecordZoneID(zoneName: CloudContainer.ZoneNames.Custom, ownerName: CKOwnerDefaultName)
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
        
        privateDatabase.addOperation(operation)
    }
    
    func deleteRecordWithID(recordID: CKRecordID, completion: DeleteRecordCompletion) {
        privateDatabase.deleteRecordWithID(recordID, completionHandler: completion)
    }
    
    // MARK: - Subscriptions
    
    func verifySubscriptions(completion: FetchSubscriptionsCompletion) {
        privateDatabase.fetchAllSubscriptionsWithCompletionHandler(completion)
    }
    
    func createSubscriptions(subscriptions: [CKSubscription], completion: CreateSubscriptionsCompletion) {
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: subscriptions, subscriptionIDsToDelete: nil)
        
        operation.modifySubscriptionsCompletionBlock = { (subscription: [CKSubscription]?, identifier: [String]?, error: NSError?) -> Void in
            completion(subscription?.first, error)
        }
        
        privateDatabase.addOperation(operation)
    }
    
    func validateSubscriptions(subscriptions: [CKSubscription]) -> Void {
        for sub in subscriptions {
            print("sub id: \(sub.subscriptionID)")
        }
    }
    
    func subscribeToPlantUpdates() -> Void {
        let subscription = CKSubscription(recordType: "Plant", predicate: NSPredicate(value: true), options: .FiresOnRecordCreation)
        
        privateDatabase.saveSubscription(subscription) { (subscription, error) -> Void in
            if let error = error {
                print("error: \(error)")
            }
            else {
                print("new subscription: \(subscription)")
            }
        }
    }
    
    // MARK: - Record Zones
    
    func fetchRecordsZones(completion: FetchRecordZonesCompletion) -> Void {
        let operation = CKFetchRecordZonesOperation.fetchAllRecordZonesOperation()
        
//        operation.qualityOfService = NSQualityOfService.UserInitiated
        
        operation.fetchRecordZonesCompletionBlock = {(zones, error) in
            completion(zones, error)
        }
        
        privateDatabase.addOperation(operation)
    }
    
    func createRecordZone(name: String, completion: CreateRecordZoneCompletion) -> Void {
        let zoneId = CKRecordZoneID(zoneName: name, ownerName: CKOwnerDefaultName)
        let zone = CKRecordZone(zoneID: zoneId)
        
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: [zone], recordZoneIDsToDelete: nil)
        
        operation.modifyRecordZonesCompletionBlock = {(zones, zoneIds, error) in
            completion(zones?.first, error)
        }
        
        privateDatabase.addOperation(operation)
    }
}
