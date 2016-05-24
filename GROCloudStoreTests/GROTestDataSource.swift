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
    
    // MARK: - Records
    
    func saveRecord(record: CKRecord, completion: RecordCompletion) {
        //
    }
    
    func recordWithID(recordID: CKRecordID, completion: RecordCompletion) {
        //
    }
    
    func recordsOfType(type: String, completion: RecordsCompletion) {
        //
    }
    
    func recordsOfType(type: String, fetched: RecordFetched, completion: QueryCompletion?) {
        //
    }
    
    func changedRecordsOfType(type: String, token: CKServerChangeToken?, completion: ChangedRecordHandler) {
        //
    }
    
    func deleteRecordWithID(recordID: CKRecordID, completion: DeleteRecordCompletion) {
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
    
    func fetchRecordsZones(completion: FetchRecordZonesCompletion) -> Void {
        //
    }
    
    func createRecordZone(name: String, completion: CreateRecordZoneCompletion) -> Void {
        //
    }
}