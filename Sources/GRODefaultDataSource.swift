//
//  GRODefaultDataSource.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 3/15/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import Foundation
import CloudKit

open class GRODefaultDataSource: CloudDataSource {
    
    public var configuration: Configuration
    
    init(configuration: Configuration) {
        self.configuration = configuration
    }
    
    public var database: CKDatabase {
        return self.container.privateCloudDatabase
    }
    
    public var container: CKContainer {
        return CKContainer(identifier: self.configuration.container.identifier)
    }
    
    // MARK: - Records
    
    public func save(withRecord record:CKRecord, completion: @escaping RecordCompletion) {
        database.save(record, completionHandler: completion)
    }
    
    public func record(withRecordID recordID: CKRecord.ID, completion: @escaping RecordCompletion) {
        database.fetch(withRecordID: recordID, completionHandler: completion)
    }
    
    public func records(ofType type: String, completion: @escaping RecordsCompletion) {
        let query = CKQuery(recordType: type, predicate: NSPredicate(value: true))
        database.perform(query, inZoneWith: nil, completionHandler: completion)
    }
    
    public func records(ofType type: String, fetched: @escaping RecordFetched, completion: QueryCompletion?) {
        let query = CKQuery(recordType: type, predicate: NSPredicate(value: true))
        let operation = CKQueryOperation(query: query)
        
        operation.recordFetchedBlock = {(record: CKRecord) in
            fetched(record)
        }
        
        operation.queryCompletionBlock = {(cursor: CKQueryOperation.Cursor?, error: Error?) in
            if let completion = completion {
                completion(cursor, error)
            }
        }
        
        database.add(operation)
    }
    
    public func changes(since token: CKServerChangeToken?, completion: @escaping DatabaseChangesHandler) {
        let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: token)
        
        var changedRecordZoneIds: [CKRecordZone.ID] = []
        operation.recordZoneWithIDChangedBlock = { (zoneId: CKRecordZone.ID) in
            changedRecordZoneIds.append(zoneId)
        }
        
        var deletedRecordZoneIds: [CKRecordZone.ID] = []
        operation.recordZoneWithIDWasDeletedBlock = { (zoneId: CKRecordZone.ID) in
            deletedRecordZoneIds.append(zoneId)
        }
        
        operation.fetchDatabaseChangesCompletionBlock = { (token: CKServerChangeToken?, more: Bool, error: Error?) in
            // TODO: need to handle more flag
            
            completion(changedRecordZoneIds, deletedRecordZoneIds, token)
        }
        
        database.add(operation)
    }
    
    public func changedRecords(inZoneIds zoneIds: [CKRecordZone.ID], tokens: [CKRecordZone.ID : CKServerChangeToken]?, completion: @escaping ChangedRecordsHandler) {
        
        let options = tokens?.optionsByRecordZoneID()
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: zoneIds, optionsByRecordZoneID: options)
        
        var changedRecords: [CKRecord] = []
        operation.recordChangedBlock = { (record: CKRecord) in
            changedRecords.append(record)
        }
        
        var deletedRecordIDs: [CKRecord.ID] = []
        operation.recordWithIDWasDeletedBlock = { (recordID: CKRecord.ID, identifier: String) in
            deletedRecordIDs.append(recordID)
        }
        
        var tokens: [CKRecordZone.ID: CKServerChangeToken] = [:]
        operation.recordZoneFetchCompletionBlock = { (zoneID: CKRecordZone.ID, token: CKServerChangeToken?, _: Data?, _: Bool, _: Error?) in
            print("record zone has changes: \(zoneID)")
            tokens[zoneID] = token
        }
        
        // not used right now
        operation.recordZoneChangeTokensUpdatedBlock = { (zoneID: CKRecordZone.ID, token: CKServerChangeToken?, data: Data?) in
            print("record zone change token updated: \(zoneID)")
        }
        
        operation.fetchRecordZoneChangesCompletionBlock = { (error: Error?) in
            completion(changedRecords, deletedRecordIDs, tokens)
        }
        
        database.add(operation)
    }
    
    public func delete(withRecordID recordID: CKRecord.ID, completion: @escaping DeleteRecordCompletion) {
        database.delete(withRecordID: recordID, completionHandler: completion)
    }
    
    // MARK: - Subscriptions
    
    public func verifySubscriptions(completion: @escaping FetchSubscriptionsCompletion) {
        database.fetchAllSubscriptions(completionHandler: completion)
    }
    
    public func createSubscriptions(subscriptions: [CKSubscription], completion: @escaping CreateSubscriptionsCompletion) {
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: subscriptions, subscriptionIDsToDelete: nil)
        
        operation.modifySubscriptionsCompletionBlock = { (subscription: [CKSubscription]?, identifier: [String]?, error: Error?) -> Void in
            completion(subscription?.first, error)
        }
        
        database.add(operation)
    }
    
    // MARK: - Record Zones
    
    public func fetchRecordsZones(completion: @escaping FetchRecordZonesCompletion) -> Void {
        // per wwdc, CKDatabaseSubscription and CKFetchDatabaseChangesOperation should replace
        // only supporting one record zone right now.
        
        let operation = CKFetchRecordZonesOperation.fetchAllRecordZonesOperation()
        operation.qualityOfService = QualityOfService.userInitiated
        
        operation.fetchRecordZonesCompletionBlock = {(zones, error) in
            completion(zones, error)
        }
        
        database.add(operation)
    }
    
    public func createRecordZone(name: String, completion: @escaping CreateRecordZoneCompletion) -> Void {
        let zoneId = CKRecordZone.ID(zoneName: name, ownerName: CKCurrentUserDefaultName)
        let zone = CKRecordZone(zoneID: zoneId)
        
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: [zone], recordZoneIDsToDelete: nil)
        
        operation.modifyRecordZonesCompletionBlock = {(zones, zoneIds, error) in
            completion(zones?.first, error)
        }
        
        database.add(operation)
    }
}

fileprivate extension Dictionary where Key: CKRecordZone.ID, Value: CKServerChangeToken {
    func optionsByRecordZoneID() -> [CKRecordZone.ID: CKFetchRecordZoneChangesOperation.ZoneOptions]? {
        var optionsByRecordZoneID: [CKRecordZone.ID: CKFetchRecordZoneChangesOperation.ZoneOptions] = [:]
        
        for (zoneId, token) in self {
            let options = CKFetchRecordZoneChangesOperation.ZoneOptions()
            options.previousServerChangeToken = token
            
            optionsByRecordZoneID[zoneId] = options
        }
        
        return (optionsByRecordZoneID.count > 0) ? optionsByRecordZoneID : nil
    }
}

fileprivate extension Array where Element : Hashable {
    var unique: [Element] {
        return Array(Set(self))
    }
}
