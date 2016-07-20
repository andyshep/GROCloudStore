//
//  CloudKitTransformable.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/8/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CloudKit
import CoreData

@objc public protocol CloudKitTransformable {
    
    var encodedSystemFields: Data? { get set }
    
    var recordType: String { get }
    var valid: Bool { get }
    
    func transform(record _: CKRecord) -> Void
    func transform() -> CKRecord
    
    func references(_ record: CKRecord) -> [CKReference: String]
    func secondaries(_ record: CKRecord) -> [String: [String: AnyObject]]
}

extension CloudKitTransformable where Self: NSManagedObject {
    
    public var record: CKRecord {
        get {
            guard let data = self.encodedSystemFields else {
                
                let psc = self.managedObjectContext?.persistentStoreCoordinator
                guard let configuration = configurationFromPersistentStore(coordinator: psc) else { fatalError() }
                
                let zoneName = configuration.CloudContainer.zoneName(forRecordType: recordType)
                let zoneId = CKRecordZoneID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)
                let recordName = UUID().uuidString
                
                let recordId = CKRecordID(recordName: recordName, zoneID: zoneId)
                let rec = CKRecord(recordType: self.recordType, recordID: recordId)
                
                self.encodedSystemFields = encodeSystemFieldsWithRecord(record: rec) as Data
                
                print("generated new record id: \(recordName)")
                
                let info = [GROObjectIDKey: objectID, GRORecordNameKey: recordName]
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: GRODidCreateRecordNotification), object: nil, userInfo: info)
                
                return rec
            }
            
            let coder = NSKeyedUnarchiver(forReadingWith: data as Data)
            coder.requiresSecureCoding = true
            
            if let record = CKRecord(coder: coder) {
                return record
            }
            else {
                fatalError()
            }
        }
        set {
            let data = NSMutableData()
            let coder = NSKeyedArchiver(forWritingWith: data)
            coder.requiresSecureCoding = true
            
            newValue.encodeSystemFields(with: coder)
            coder.finishEncoding()
            
            self.encodedSystemFields = NSData(data: data as Data as Data) as Data
        }
    }
}

private func encodeSystemFieldsWithRecord(record: CKRecord) -> NSData {
    let data = NSMutableData()
    let coder = NSKeyedArchiver(forWritingWith: data)
    coder.requiresSecureCoding = true
    
    record.encodeSystemFields(with: coder)
    coder.finishEncoding()
    
    return NSData(data: data as Data)
}

private func configurationFromPersistentStore(coordinator: NSPersistentStoreCoordinator?) -> Configuration? {
    guard let _ = coordinator else { return nil }
    
    for store in coordinator!.persistentStores {
        if let incremental = store as? GROIncrementalStore {
            return incremental.configuration
        }
    }
    
    return nil
}
