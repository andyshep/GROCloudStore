//
//  GROCloudDataSource.swift
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

public typealias ChangedRecordHandler = (changed: [CKRecord], deleted: [CKRecordID], token: CKServerChangeToken?) -> Void

public protocol GROCloudDataSource {
    
    func saveRecord(record:CKRecord, completion: RecordCompletion)
    func recordWithID(recordID:CKRecordID, completion: RecordCompletion)
    
    func recordsOfType(type: String, completion: RecordsCompletion)
    func recordsOfType(type: String, fetched: RecordFetched, completion: QueryCompletion?)
    
    func changedRecordsOfType(type: String, token: CKServerChangeToken?, completion: ChangedRecordHandler)
    func deleteRecordWithID(recordID: CKRecordID, completion: DeleteRecordCompletion)
    func verifySubscriptions(completion: FetchSubscriptionsCompletion)
    
    func createSubscriptions(subscriptions: [CKSubscription], completion: CreateSubscriptionsCompletion)
    func validateSubscriptions(subscriptions: [CKSubscription]) -> Void
    
    func fetchRecordsZones(completion: FetchRecordZonesCompletion) -> Void
    func createRecordZone(name: String, completion: CreateRecordZoneCompletion) -> Void
}
