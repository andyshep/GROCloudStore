//
//  InjestDeletedRecordsOperation.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/8/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CoreData
import CloudKit

final class InjestDeletedRecordsOperation: Operation {
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
        return self.operation.deletedRecordIDs
    }
    
    override func main() {
        if self.recordIDs.count == 0 { return }
        
        let deletedRecordIDs = self.operation.deletedRecordIDs
        
        backingContext.performAndWait {
            
            for record in deletedRecordIDs {
                let identifier = record.recordName
                guard let entity = self.delegate?.entity(for: identifier, in: self.backingContext) else {
                    // if the record was never sync'd to the device
                    // it won't be available for deletion.
                    continue
                }
                
                do {
                    guard let objectId = try self.delegate?.backingObjectID(for: entity, with: identifier as NSString?) else { return }
                    let obj = self.backingContext.object(with: objectId)
                    self.backingContext.delete(obj)
                } catch {
                    print("could not find backing object for identifier: \(error)")
                }
            }
        }
        
        context.performAndWait { 
            for record in deletedRecordIDs {
                let identifier = record.recordName
                guard let entity = self.delegate?.entity(for: identifier, in: self.context) else {
                    // if the record was never sync'd to the device
                    // it won't be available for deletion.
                    continue
                }
                
                do {
                    guard let objectId = try self.delegate?.objectID(for: entity, with: identifier as NSString?) else { return }
                    let obj = self.context.object(with: objectId)
                    self.context.delete(obj)
                } catch {
                    print("could not find object for identifier: \(error)")
                }
            }
        }
    }
}
