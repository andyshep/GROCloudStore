//
//  CloudKitTransformable.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/8/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CloudKit
import CoreData

@objc protocol CloudKitTransformable {
    
    var encodedSystemFields: NSData? { get set }
    
    var recordType: String { get }
    var valid: Bool { get }
    
    func transform(record _: CKRecord) -> Void
    func transform() -> CKRecord
    
    func references(record: CKRecord) -> [CKReference: String]
}

extension CloudKitTransformable where Self: NSManagedObject {
    
    var record: CKRecord {
        get {
            guard let data = self.encodedSystemFields else {
                let zoneId = CKRecordZoneID(zoneName: CloudContainer.ZoneNames.Custom, ownerName: CKOwnerDefaultName)
                let recordName = NSUUID().UUIDString
                
                let recordId = CKRecordID(recordName: recordName, zoneID: zoneId)
                let rec = CKRecord(recordType: self.recordType, recordID: recordId)
                
                self.encodedSystemFields = encodeSystemFieldsWithRecord(rec)
                
                print("generated new record id: \(recordName)")
                
                let info = [Key.ObjectID: objectID, Key.RecordName: recordName]
                NSNotificationCenter.defaultCenter().postNotificationName(GRODidCreateRecordNotification, object: nil, userInfo: info)
                
                return rec
            }
            
            let coder = NSKeyedUnarchiver(forReadingWithData: data)
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
            let coder = NSKeyedArchiver(forWritingWithMutableData: data)
            coder.requiresSecureCoding = true
            
            newValue.encodeSystemFieldsWithCoder(coder)
            coder.finishEncoding()
            
            self.encodedSystemFields = NSData(data: data)
        }
    }
}

private func encodeSystemFieldsWithRecord(record: CKRecord) -> NSData {
    let data = NSMutableData()
    let coder = NSKeyedArchiver(forWritingWithMutableData: data)
    coder.requiresSecureCoding = true
    
    record.encodeSystemFieldsWithCoder(coder)
    coder.finishEncoding()
    
    return NSData(data: data)
}