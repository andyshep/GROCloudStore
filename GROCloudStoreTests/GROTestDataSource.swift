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
    
    func saveRecord(_ record: CKRecord, completion: RecordCompletion) {
        //
    }
    
    func recordWithID(_ recordID: CKRecordID, completion: RecordCompletion) {
        //
    }
    
    func recordsOfType(_ type: String, completion: RecordsCompletion) {
        //
    }
    
    func recordsOfType(_ type: String, fetched: RecordFetched, completion: QueryCompletion?) {
        //
    }
    
    func changedRecordsOfType(_ type: String, token: CKServerChangeToken?, completion: ChangedRecordHandler) {
        //
    }
    
    func deleteRecordWithID(_ recordID: CKRecordID, completion: DeleteRecordCompletion) {
        //
    }
    
    // MARK: - Subscriptions
    
    func verifySubscriptions(_ completion: FetchSubscriptionsCompletion) {
        //
    }
    
    func createSubscriptions(_ subscriptions: [CKSubscription], completion: CreateSubscriptionsCompletion) {
        //
    }
    
    // MARK: - Record Zones
    
    func fetchRecordsZones(_ completion: FetchRecordZonesCompletion) -> Void {
        //
    }
    
    func createRecordZone(_ name: String, completion: CreateRecordZoneCompletion) -> Void {
        //
    }
}
