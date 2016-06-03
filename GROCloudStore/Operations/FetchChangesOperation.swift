//
//  FetchChangesOperation.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/8/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CoreData
import CloudKit

class FetchChangesOperation: AsyncOperation {
    let context: NSManagedObjectContext
    let backingContext: NSManagedObjectContext
    let request: NSPersistentStoreRequest
    
    var insertedRecords: [CKRecord] = []
    var updatedRecords: [CKRecord] = []
    var deletedRecordIDs: [CKRecordID] = []
    
    weak var delegate: ManagedObjectIDProvider?
    
    private let dataSource: CloudDataSource
    
    required init(request: NSFetchRequest, context: NSManagedObjectContext, backingContext: NSManagedObjectContext, dataSource: CloudDataSource) {
        self.request = request
        self.context = context
        self.backingContext = backingContext
        self.dataSource = dataSource
        
        super.init()
    }
    
    override func main() {
        guard let request = self.request as? NSFetchRequest else { fatalError() }
        let recordType = request.recordType
        
        var token: CKServerChangeToken? = nil
        if let tokenObj = existingChangeToken(in: backingContext) {
            if let lastToken = NSKeyedUnarchiver.unarchiveObject(with: tokenObj.content) as? CKServerChangeToken {
                token = lastToken
            }
        }
        
        dataSource.changedRecordsOfType(type: recordType, token: token) { (changedRecords, deletedRecordIDs, token) in
            
            for record in changedRecords {
                self.recordDidChange(record: record)
            }
            
            for recordID in deletedRecordIDs {
                self.recordIDWasDeleted(recordID: recordID)
            }
            
            self.saveToken(token: token)
            
            self.finish()
        }
    }
    
    // MARK: - Private
    
    private func recordDidChange(record: CKRecord) -> Void {
        self.updatedRecords.append(record)
    }
    
    private func recordIDWasDeleted(recordID: CKRecordID) -> Void {
        self.deletedRecordIDs.append(recordID)
    }
    
    private func changeToken(in context: NSManagedObjectContext) -> GROChangeToken {
        if let token = self.existingChangeToken(in: context) {
            return token
        }
        
        return self.newChangeToken(in: context)
    }
    
    private func existingChangeToken(in context: NSManagedObjectContext) -> GROChangeToken? {
        let request = NSFetchRequest(entityName: GROChangeToken.entityName)
        do {
            let result = try context.fetch(request)
            if let token = result.first as? GROChangeToken {
                return token
            }
        }
        catch {
            print("unhandled error: \(error)")
        }
        
        return nil
    }
    
    private func newChangeToken(in context: NSManagedObjectContext) -> GROChangeToken {
        let object = GROChangeToken.newObject(in: context)
        guard let token = object as? GROChangeToken else {
            fatalError()
        }
        
        return token
    }
    
    private func saveToken(token: CKServerChangeToken?) {
        if let token = token {
            self.backingContext.performAndWait {
                let savedChangeToken = self.changeToken(in: self.backingContext)
                savedChangeToken.content = NSKeyedArchiver.archivedData(withRootObject: token)
                self.backingContext.saveOrLogError()
            }
        }
    }
}

extension FetchChangesOperation: RecordChangeOperation { }