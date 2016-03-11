//
//  PushChangesOperation.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/19/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CloudKit
import CoreData

class PushChangesOperation: AsyncOperation {
    let context: NSManagedObjectContext
    let backingContext: NSManagedObjectContext
    let request: NSPersistentStoreRequest
    
    var insertedRecords: [CKRecord]
    var updatedRecords: [CKRecord]
    var deletedRecordIDs: [CKRecordID]
    
    private let cloudDataSource = GROCloudDataSource()
    
    init(request: NSSaveChangesRequest, context: NSManagedObjectContext, backingContext: NSManagedObjectContext) {
        self.request = request
        self.context = context
        self.backingContext = backingContext
        
        self.insertedRecords = request.insertedRecords
        self.updatedRecords = request.updatedRecords
        self.deletedRecordIDs = request.deletedRecordIDs
    }
    
    override func main() {
        
        let records = insertedRecords + updatedRecords
        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: deletedRecordIDs)
        
        operation.modifyRecordsCompletionBlock = {(records, recordIds, error) in
            // TODO: handle error
            self.finish()
        }
        
        self.cloudDataSource.privateDatabase.addOperation(operation)
    }
}

extension PushChangesOperation: RecordChangeOperation { }