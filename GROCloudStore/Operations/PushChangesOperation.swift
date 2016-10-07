//
//  PushChangesOperation.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/19/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CloudKit
import CoreData
import Foundation

final internal class PushChangesOperation: AsyncOperation {
    let context: NSManagedObjectContext
    let backingContext: NSManagedObjectContext
    let request: NSPersistentStoreRequest
    
    private(set) var insertedRecords: [CKRecord]
    private(set) var updatedRecords: [CKRecord]
    private(set) var deletedRecordIDs: [CKRecordID]
    
    private let dataSource: CloudDataSource
    
    init(request: NSSaveChangesRequest, context: NSManagedObjectContext, backingContext: NSManagedObjectContext, dataSource: CloudDataSource) {
        self.request = request
        self.context = context
        self.backingContext = backingContext
        self.dataSource = dataSource
        
        self.insertedRecords = request.insertedRecords
        self.updatedRecords = request.updatedRecords
        self.deletedRecordIDs = request.deletedRecordIDs
    }
    
    override func main() {
        
        let completion: (Bool) -> () = { [unowned self] done in
            if done { self.finish() }
        }
        
        let createZoneCompletion: (CKRecordZone?, Error?) -> () = { recordZone, error in
            guard error == nil else {
                return completion(false)
            }
            
            let operation = self.modifyRecordsOperation()
            operation.modifyRecordsCompletionBlock = {(records, recordIds, error) in
                return completion(true)
            }
            
            self.dataSource.database.add(operation)
        }
        
        let operation = modifyRecordsOperation()
        
        operation.modifyRecordsCompletionBlock = {(records, recordIds, error) in
            guard error == nil else {
                if error!._domain == CKErrorDomain {
                    if error!._code == 2 {
                        // record zone missing
                        
                        let configuration = self.dataSource.configuration
                        let zoneName = configuration.CloudContainer.CustomZoneNames.first!
                        self.dataSource.createRecordZone(name: zoneName, completion: createZoneCompletion)
                        
                        return completion(false)
                    } else {
                        attemptCloudKitRecoveryFrom(error: error! as NSError)
                    }
                } else {
                    fatalError()
                }
                
                return completion(false)
            }
            
            completion(true)
        }
        
        self.dataSource.database.add(operation)
    }
    
    private func modifyRecordsOperation() -> CKModifyRecordsOperation {
        let records = insertedRecords + updatedRecords
        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: deletedRecordIDs)
        operation.qualityOfService = QualityOfService.userInitiated
        
        return operation
    }
}

extension PushChangesOperation: RecordChangeOperation { }
