//
//  CloudDataSource.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 7/11/15.
//  Copyright © 2015 Andrew Shepard. All rights reserved.
//

import Foundation
import CloudKit

public typealias RecordsCompletion = ([CKRecord]?, Error?) -> Void
public typealias RecordCompletion = (CKRecord?, Error?) -> Void
public typealias DeleteRecordCompletion = (CKRecordID?, Error?) -> Void

public typealias FetchSubscriptionsCompletion = ([CKSubscription]?, Error?) -> Void
public typealias CreateSubscriptionsCompletion = (CKSubscription?, Error?) -> Void

public typealias RecordFetched = (CKRecord) -> Void
public typealias QueryCompletion = (CKQueryCursor?, Error?) -> Void

public typealias FetchRecordZonesCompletion = ([CKRecordZoneID: CKRecordZone]?, Error?) -> Void
public typealias CreateRecordZoneCompletion = (CKRecordZone?, Error?) -> Void

public typealias DatabaseChangesHandler = (_ changed: [CKRecordZoneID], _ deleted: [CKRecordZoneID], _ token: CKServerChangeToken?) -> Void
public typealias ChangedRecordsHandler = (_ changed: [CKRecord], _ deleted: [CKRecordID], _ tokens: [CKRecordZoneID: CKServerChangeToken]) -> Void

public protocol CloudDataSource {
    
    var configuration: Configuration { get }
    var database: CKDatabase { get }
    var container: CKContainer { get }
    
    func save(withRecord record: CKRecord, completion: @escaping RecordCompletion)
    func record(withRecordID recordID: CKRecordID, completion: @escaping RecordCompletion)
    
    func records(ofType type: String, completion: @escaping RecordsCompletion)
    func records(ofType type: String, fetched: @escaping RecordFetched, completion: QueryCompletion?)
    
    func changes(since token: CKServerChangeToken?, completion: @escaping DatabaseChangesHandler)
    func changedRecords(inZoneIds zoneIds: [CKRecordZoneID], tokens: [CKRecordZoneID: CKServerChangeToken]?, completion: @escaping ChangedRecordsHandler)
    
    func delete(withRecordID recordID: CKRecordID, completion: @escaping DeleteRecordCompletion)
    
    func verifySubscriptions(completion: @escaping FetchSubscriptionsCompletion)
    func createSubscriptions(subscriptions: [CKSubscription], completion: @escaping CreateSubscriptionsCompletion)
    
    func fetchRecordsZones(completion: @escaping FetchRecordZonesCompletion) -> Void
    func createRecordZone(name: String, completion: @escaping CreateRecordZoneCompletion) -> Void
    
}
