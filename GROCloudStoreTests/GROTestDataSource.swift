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
    
    func save(withRecord record: CKRecord, completion: @escaping RecordCompletion) {
        //
    }
    
    func record(withRecordID recordID: CKRecordID, completion: @escaping  RecordCompletion) {
        //
    }
    
    func records(ofType type: String, completion: @escaping  RecordsCompletion) {
        //
    }
    
    func records(ofType type: String, fetched: @escaping RecordFetched, completion: QueryCompletion?) {
        //
    }
    
    func changedRecordsOfType(_ type: String, token: CKServerChangeToken?, completion: ChangedRecordsHandler) {
        //
    }
    
    func changedRecords(inZoneIds zoneIds: [CKRecordZoneID], tokens: [CKRecordZoneID : CKServerChangeToken]?, completion: @escaping ChangedRecordsHandler) {
        //
    }
    
    func delete(withRecordID recordID: CKRecordID, completion: @escaping DeleteRecordCompletion) {
        //
    }
    
    // MARK: - Subscriptions
    
    func verifySubscriptions(completion: @escaping FetchSubscriptionsCompletion) {
        //
    }
    
    func createSubscriptions(subscriptions: [CKSubscription], completion: @escaping CreateSubscriptionsCompletion) {
        //
    }
    
    // MARK: - Record Zones
    
    func fetchRecordsZones(completion: @escaping FetchRecordZonesCompletion) {
        //
    }
    
    func createRecordZone(name: String, completion: @escaping CreateRecordZoneCompletion) {
        //
    }
    
    func changes(since token: CKServerChangeToken?, completion: @escaping DatabaseChangesHandler) {
        //
    }
    
    
}
