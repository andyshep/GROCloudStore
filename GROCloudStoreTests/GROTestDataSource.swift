//
//  GROTestDataSource.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 3/15/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import Foundation
import CloudKit
@testable import GROCloudStore

class GROTestDataSource: CloudDataSource {
    
    var database: CKDatabase {
        fatalError()
    }
    
    var configuration: Configuration {
        fatalError()
    }
    
    var container: CKContainer {
        fatalError()
    }
    
    
    // MARK: - Records
    
    func save(withRecord record: CKRecord, completion: RecordCompletion) {
        //
    }
    
    func record(withRecordID recordID: CKRecordID, completion: RecordCompletion) {
        //
    }
    
    func records(ofType type: String, completion: RecordsCompletion) {
        //
    }
    
    func records(ofType type: String, fetched: RecordFetched, completion: QueryCompletion?) {
        //
    }
    
    func changedRecordsOfType(_ type: String, token: CKServerChangeToken?, completion: ChangedRecordsHandler) {
        //
    }
    
    func changedRecords(inZoneIds zoneIds: [CKRecordZoneID], tokens: [CKRecordZoneID : CKServerChangeToken]?, completion: ChangedRecordsHandler) {
        //
    }
    
    func delete(withRecordID recordID: CKRecordID, completion: DeleteRecordCompletion) {
        //
    }
    
    // MARK: - Subscriptions
    
    func verifySubscriptions(completion: FetchSubscriptionsCompletion) {
        //
    }
    
    func createSubscriptions(subscriptions: [CKSubscription], completion: CreateSubscriptionsCompletion) {
        //
    }
    
    // MARK: - Record Zones
    
    func fetchRecordsZones(completion: FetchRecordZonesCompletion) {
        //
    }
    
    func createRecordZone(name: String, completion: CreateRecordZoneCompletion) {
        //
    }
    
    func changes(since token: CKServerChangeToken?, completion: DatabaseChangesHandler) {
        //
    }
    
    
}
