//
//  ZoneChangesOperation.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/8/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CoreData
import CloudKit

class ZoneChangesOperation: AsyncOperation {
    let context: NSManagedObjectContext
    let backingContext: NSManagedObjectContext
    let request: NSPersistentStoreRequest
    let operation: DatabaseChangesOperation
    
    private(set) var insertedRecords: [CKRecord] = []
    private(set) var updatedRecords: [CKRecord] = []
    private(set) var deletedRecordIDs: [CKRecordID] = []
    
    weak var delegate: ManagedObjectIDProvider?
    
    private let dataSource: CloudDataSource
    
    required init(operation: DatabaseChangesOperation, request: NSPersistentStoreRequest, context: NSManagedObjectContext) {
        self.request = request
        self.operation = operation
        
        self.backingContext = operation.context
        self.context = context
        self.dataSource = operation.dataSource
        
        super.init()
    }
    
    override func main() {
        let zoneIds = operation.changedRecordZoneIds
        let tokens = changeTokens(forZoneIds: zoneIds, in: backingContext)
        
        dataSource.changedRecords(inZoneIds: zoneIds, tokens: tokens) { (changedRecords, deletedRecordIDs, changedZones) in
            for record in changedRecords {
                self.recordDidChange(record)
            }
            
            for recordID in deletedRecordIDs {
                self.recordIDWasDeleted(recordID)
            }
            
            for (zoneId, token) in changedZones {
                save(token: token, forRecordZoneId: zoneId, in: self.backingContext)
            }
            
            self.finish()
        }
    }
    
    // MARK: - Private
    
    private func recordDidChange(_ record: CKRecord) -> Void {
        self.updatedRecords.append(record)
    }
    
    private func recordIDWasDeleted(_ recordID: CKRecordID) -> Void {
        self.deletedRecordIDs.append(recordID)
    }
}

extension ZoneChangesOperation: RecordChangeOperation { }
