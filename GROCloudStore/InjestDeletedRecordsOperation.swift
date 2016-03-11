//
//  InjestDeletedRecordsOperation.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/8/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CoreData
import CloudKit

class InjestDeletedRecordsOperation: NSOperation {
    unowned var operation: RecordChangeOperation
    weak var delegate: ManagedObjectIDProvider?
    
    required init(operation: RecordChangeOperation) {
        self.operation = operation
        super.init()
    }
    
    private var context: NSManagedObjectContext {
        return self.operation.context
    }
    
    private var backingContext: NSManagedObjectContext {
        return self.operation.backingContext
    }
    
    private var recordIDs: [CKRecordID] {
        return self.operation.deletedRecordIDs ?? []
    }
    
    override func main() {
        if self.recordIDs.count == 0 { return }
        
        let deletedRecordIDs = self.operation.deletedRecordIDs
        
        backingContext.performBlockAndWait {
            
            for record in deletedRecordIDs {
                let identifier = record.recordName
                guard let entity = self.delegate?.entityForIdentifier(identifier, context: self.context) else {
                    fatalError("entity not found")
                }
                
                do {
                    guard let objectId = try self.delegate?.backingObjectIDForEntity(entity, identifier: identifier) else { return }
                    let obj = self.backingContext.objectWithID(objectId)
                    self.backingContext.deleteObject(obj)
                }
                catch {
                    print("could not find backing object for identifier: \(error)")
                }
            }
        }
        
        context.performBlockAndWait { 
            for record in deletedRecordIDs {
                let identifier = record.recordName
                guard let entity = self.delegate?.entityForIdentifier(identifier, context: self.context) else {
                    fatalError("entity not found")
                }
                
                do {
                    guard let objectId = try self.delegate?.objectIDForEntity(entity, identifier: identifier) else { return }
                    let obj = self.context.objectWithID(objectId)
                    self.context.deleteObject(obj)
                }
                catch {
                    print("could not find object for identifier: \(error)")
                }
            }
        }
    }
}
