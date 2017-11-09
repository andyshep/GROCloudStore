//
//  CloudKitTransformable.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/8/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CloudKit
import CoreData

/// A protocol the defines how an object is to be transformed for CloudKit.
@objc public protocol CloudKitTransformable {
    
    /// The type of `CKRecord` the object should be transformed into.
    var recordType: String { get }
    
    func transform(record _: CKRecord) -> Void
    func transform() -> CKRecord
    
    func references(for record: CKRecord) -> [CKReference: String]
    func secondaries(for record: CKRecord) -> [String: [String: AnyObject]]
    
    var encodedSystemFields: Data? { get set }
    var valid: Bool { get }
}

extension CloudKitTransformable where Self: NSManagedObject {
    
    private var encodedSystemFields: Data? {
        
        // http://stackoverflow.com/a/33125474
        
        get {
            let mobj = self as NSManagedObject
            guard let data = mobj.value(forKey: "encodedSystemFields") as? Data else {
                return nil
            }
            
            return data
        }
        
        set {
            let mobj = self as NSManagedObject
            mobj.setValue(newValue, forKey: "encodedSystemFields")
        }
    }
    
    public var record: CKRecord {
        get {
            guard let data = self.encodedSystemFields else {
                
                let psc = self.managedObjectContext?.persistentStoreCoordinator
                guard let configuration = configurationFromPersistentStore(coordinator: psc) else { fatalError() }
                
                let zoneName = configuration.container.zoneName(forRecordType: recordType)
                let zoneId = CKRecordZoneID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)
                let recordName = UUID().uuidString
                
                let recordId = CKRecordID(recordName: recordName, zoneID: zoneId)
                let rec = CKRecord(recordType: self.recordType, recordID: recordId)
                
                self.encodedSystemFields = encodeSystemFieldsWithRecord(record: rec) as Data
                
                print("generated new record id: \(recordName)")
                
                let info = [GROObjectIDKey: objectID, GRORecordNameKey: recordName] as [String : Any]
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
            
            self.encodedSystemFields = data as Data
        }
    }
}

fileprivate func encodeSystemFieldsWithRecord(record: CKRecord) -> NSData {
    let data = NSMutableData()
    let coder = NSKeyedArchiver(forWritingWith: data)
    coder.requiresSecureCoding = true
    
    record.encodeSystemFields(with: coder)
    coder.finishEncoding()
    
    return NSData(data: data as Data)
}

fileprivate func configurationFromPersistentStore(coordinator: NSPersistentStoreCoordinator?) -> Configuration? {
    guard let _ = coordinator else { return nil }
    
    for store in coordinator!.persistentStores {
        if let incremental = store as? GROIncrementalStore {
            return incremental.configuration
        }
    }
    
    return nil
}
