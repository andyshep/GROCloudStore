//
//  GRODefaultDataSource.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 3/15/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import Foundation
import CloudKit

public class GRODefaultDataSource: CloudDataSource {
    
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
    
    public func save(withRecord record:CKRecord, completion: RecordCompletion) {
        database.save(record, completionHandler: completion)
    }
    
    public func record(withRecordID recordID: CKRecordID, completion: RecordCompletion) {
        database.fetch(withRecordID: recordID, completionHandler: completion)
    }
    
    public func records(ofType type: String, completion: RecordsCompletion) {
        let query = CKQuery(recordType: type, predicate: Predicate(value: true))
        database.perform(query, inZoneWith: nil, completionHandler: completion)
    }
    
    public func records(ofType type: String, fetched: RecordFetched, completion: QueryCompletion?) {
        let query = CKQuery(recordType: type, predicate: Predicate(value: true))
        let operation = CKQueryOperation(query: query)
        
        operation.recordFetchedBlock = {(record: CKRecord) in
            fetched(record)
        }
        
        operation.queryCompletionBlock = {(cursor: CKQueryCursor?, error: NSError?) in
            if let completion = completion {
                completion(cursor, error)
            }
        }
        
        database.add(operation)
    }
    
    public func changes(since token: CKServerChangeToken?, completion: DatabaseChangesHandler) {
        let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: token)
        
        var changedRecordZoneIds: [CKRecordZoneID] = []
        operation.recordZoneWithIDChangedBlock = { (zoneId: CKRecordZoneID) in
            changedRecordZoneIds.append(zoneId)
        }
        
        var deletedRecordZoneIds: [CKRecordZoneID] = []
        operation.recordZoneWithIDWasDeletedBlock = { (zoneId: CKRecordZoneID) in
            deletedRecordZoneIds.append(zoneId)
        }
        
        operation.fetchDatabaseChangesCompletionBlock = { (token: CKServerChangeToken?, more: Bool, error: NSError?) in
            completion(changed: changedRecordZoneIds, deleted: deletedRecordZoneIds, token: token)
        }
        
        database.add(operation)
    }
    
    public func changedRecords(inZoneIds zoneIds: [CKRecordZoneID], tokens: [CKRecordZoneID : CKServerChangeToken]?, completion: ChangedRecordsHandler) {
        
        let options = tokens?.optionsByRecordZoneID()
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: zoneIds, optionsByRecordZoneID: options)
        
        var changedRecords: [CKRecord] = []
        operation.recordChangedBlock = { (record: CKRecord) in
            changedRecords.append(record)
        }
        
        var deletedRecordIDs: [CKRecordID] = []
        operation.recordWithIDWasDeletedBlock = { (recordID: CKRecordID, identifier: String) in
            deletedRecordIDs.append(recordID)
        }
        
        var tokens: [CKRecordZoneID: CKServerChangeToken] = [:]
        operation.recordZoneFetchCompletionBlock = { (zoneID: CKRecordZoneID, token: CKServerChangeToken?, _: Data?, _: Bool, _: NSError?) in
            print("record zone has changes: \(zoneID)")
            tokens[zoneID] = token
        }
        
        // not used right now
        operation.recordZoneChangeTokensUpdatedBlock = { (zoneID: CKRecordZoneID, token: CKServerChangeToken?, data: Data?) in
            print("record zone change token updated: \(zoneID)")
        }
        
        operation.fetchRecordZoneChangesCompletionBlock = { (error: NSError?) in
            completion(changed: changedRecords, deleted: deletedRecordIDs, tokens: tokens)
        }
        
        database.add(operation)
    }
    
    public func delete(withRecordID recordID: CKRecordID, completion: DeleteRecordCompletion) {
        database.delete(withRecordID: recordID, completionHandler: completion)
    }
    
    // MARK: - Subscriptions
    
    public func verifySubscriptions(completion: FetchSubscriptionsCompletion) {
        database.fetchAll(completionHandler: completion)
    }
    
    public func createSubscriptions(subscriptions: [CKSubscription], completion: CreateSubscriptionsCompletion) {
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: subscriptions, subscriptionIDsToDelete: nil)
        
        operation.modifySubscriptionsCompletionBlock = { (subscription: [CKSubscription]?, identifier: [String]?, error: NSError?) -> Void in
            completion(subscription?.first, error)
        }
        
        database.add(operation)
    }
    
    // MARK: - Record Zones
    
    public func fetchRecordsZones(completion: FetchRecordZonesCompletion) -> Void {
        // per wwdc, CKDatabaseSubscription and CKFetchDatabaseChangesOperation should replace
        
        let operation = CKFetchRecordZonesOperation.fetchAllRecordZonesOperation()
        operation.qualityOfService = QualityOfService.userInitiated
        
        operation.fetchRecordZonesCompletionBlock = {(zones, error) in
            completion(zones, error)
        }
        
        database.add(operation)
    }
    
    public func createRecordZone(name: String, completion: CreateRecordZoneCompletion) -> Void {
        let zoneId = CKRecordZoneID(zoneName: name, ownerName: CKCurrentUserDefaultName)
        let zone = CKRecordZone(zoneID: zoneId)
        
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: [zone], recordZoneIDsToDelete: nil)
        
        operation.modifyRecordZonesCompletionBlock = {(zones, zoneIds, error) in
            completion(zones?.first, error)
        }
        
        database.add(operation)
    }
}

extension Dictionary where Key: CKRecordZoneID, Value: CKServerChangeToken {
    func optionsByRecordZoneID() -> [CKRecordZoneID: CKFetchRecordZoneChangesOptions]? {
        var optionsByRecordZoneID: [CKRecordZoneID: CKFetchRecordZoneChangesOptions] = [:]
        
        for (zoneId, token) in self {
            let options = CKFetchRecordZoneChangesOptions()
            options.previousServerChangeToken = token
            
            optionsByRecordZoneID[zoneId] = options
        }
        
        return (optionsByRecordZoneID.count > 0) ? optionsByRecordZoneID : nil
    }
}

extension Array where Element : Hashable {
    var unique: [Element] {
        return Array(Set(self))
    }
}
