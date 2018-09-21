//
//  Todos+Transformables.swift
//  Todos
//
//  Created by Andrew Shepard on 5/23/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import Foundation
import CoreData
import GROCloudStore

extension Todo: ManagedObjectTransformable {
    
    func transform(using object: NSManagedObject) {
        guard let item = object.value(forKeyPath: "item") as? String else { return }
        self.item = item
        
        guard let created = object.value(forKeyPath: "created") as? Date else { return }
        self.created = created
        
        guard let data = object.value(forKeyPath: "encodedSystemFields") as? Data else { fatalError() }
        self.encodedSystemFields = data
    }
    
    class var entityName: String {
        return "Todo"
    }
}

extension Todo: CloudKitTransformable {
    
    func transform(record: CKRecord) {
        guard let item = record["item"] as? String else { return }
        self.item = item
        
        guard let created = record["created"] as? Date else { return }
        self.created = created
        
        self.record = record
    }
    
    func transform() -> CKRecord {
        let record = self.record
        record["item"] = NSString(string: self.item ?? "")
        
        let interval = self.created?.timeIntervalSinceReferenceDate ?? 0
        record["created"] = NSDate(timeIntervalSinceReferenceDate: interval)
        
        return record
    }
    
    func references(for record: CKRecord) -> [CKRecord.Reference: String] {
        return [:]
    }
    
    var recordType: String {
        return "Todo"
    }
    
    var valid: Bool {
        return (self.item != "")
    }
    
    func secondaries(for record: CKRecord) -> [String : [String : AnyObject]] {
        return [:]
    }
}
