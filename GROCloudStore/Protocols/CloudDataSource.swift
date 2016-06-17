//
//  CloudDataSource.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 7/11/15.
//  Copyright © 2015 Andrew Shepard. All rights reserved.
//

import Foundation
import CloudKit

public typealias RecordsCompletion = ([CKRecord]?, NSError?) -> Void
public typealias RecordCompletion = (CKRecord?, NSError?) -> Void
public typealias DeleteRecordCompletion = (CKRecordID?, NSError?) -> Void

public typealias FetchSubscriptionsCompletion = ([CKSubscription]?, NSError?) -> Void
public typealias CreateSubscriptionsCompletion = (CKSubscription?, NSError?) -> Void

public typealias RecordFetched = (CKRecord) -> Void
public typealias QueryCompletion = (CKQueryCursor?, NSError?) -> Void

public typealias FetchRecordZonesCompletion = ([CKRecordZoneID: CKRecordZone]?, NSError?) -> Void
public typealias CreateRecordZoneCompletion = (CKRecordZone?, NSError?) -> Void

public typealias DatabaseChangesHandler = (changed: [CKRecordZoneID], deleted: [CKRecordZoneID], token: CKServerChangeToken?) -> Void
public typealias ChangedRecordsHandler = (changed: [CKRecord], deleted: [CKRecordID], tokens: [CKRecordZoneID: CKServerChangeToken]) -> Void

public protocol CloudDataSource {
    
    var configuration: Configuration { get }
    var database: CKDatabase { get }
    var container: CKContainer { get }
    
    func save(withRecord record: CKRecord, completion: RecordCompletion)
    func record(withRecordID recordID: CKRecordID, completion: RecordCompletion)
    
    func records(ofType type: String, completion: RecordsCompletion)
    func records(ofType type: String, fetched: RecordFetched, completion: QueryCompletion?)
    
    func changes(since token: CKServerChangeToken?, completion: DatabaseChangesHandler)
    func changedRecords(inZoneIds zoneIds: [CKRecordZoneID], tokens: [CKRecordZoneID: CKServerChangeToken]?, completion: ChangedRecordsHandler)
    
    func delete(withRecordID recordID: CKRecordID, completion: DeleteRecordCompletion)
    
    func verifySubscriptions(completion: FetchSubscriptionsCompletion)
    func createSubscriptions(subscriptions: [CKSubscription], completion: CreateSubscriptionsCompletion)
    
    func fetchRecordsZones(completion: FetchRecordZonesCompletion) -> Void
    func createRecordZone(name: String, completion: CreateRecordZoneCompletion) -> Void
    
}
