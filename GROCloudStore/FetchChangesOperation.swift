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
    
    private let cloudDataSource = GROCloudDataSource()
    
    required init(request: NSFetchRequest, context: NSManagedObjectContext, backingContext: NSManagedObjectContext) {
        self.request = request
        self.context = context
        self.backingContext = backingContext
        
        super.init()
    }
    
    override func main() {
        guard let request = self.request as? NSFetchRequest else { fatalError() }
        let recordType = request.recordType
        
        var token: CKServerChangeToken? = nil
        if let tokenObj = existingChangeTokenInContext(backingContext) {
            if let lastToken = NSKeyedUnarchiver.unarchiveObjectWithData(tokenObj.content) as? CKServerChangeToken {
                token = lastToken
            }
        }
        
        cloudDataSource.changedRecordsOfType(recordType, token: token) { (changedRecords, deletedRecordIDs, token) in
            
            for record in changedRecords {
                self.recordDidChange(record)
            }
            
            for recordID in deletedRecordIDs {
                self.recordIDWasDeleted(recordID)
            }
            
            self.saveToken(token)
            
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
    
    private func changeTokenInContext(context: NSManagedObjectContext) -> GROChangeToken {
        if let token = self.existingChangeTokenInContext(context) {
            return token
        }
        
        return self.newChangeTokenInContext(context)
    }
    
    private func existingChangeTokenInContext(context: NSManagedObjectContext) -> GROChangeToken? {
        let request = NSFetchRequest(entityName: GROChangeToken.entityName)
        do {
            let result = try context.executeFetchRequest(request)
            if let token = result.first as? GROChangeToken {
                return token
            }
        }
        catch {
            print("unhandled error: \(error)")
        }
        
        return nil
    }
    
    private func newChangeTokenInContext(context: NSManagedObjectContext) -> GROChangeToken {
        let object = GROChangeToken.newObjectInContext(context)
        guard let token = object as? GROChangeToken else {
            fatalError()
        }
        
        return token
    }
    
    private func saveToken(token: CKServerChangeToken?) {
        if let token = token {
            self.backingContext.performBlockAndWait {
                let savedChangeToken = self.changeTokenInContext(self.backingContext)
                savedChangeToken.content = NSKeyedArchiver.archivedDataWithRootObject(token)
                self.backingContext.saveOrLogError()
            }
        }
    }
}

extension FetchChangesOperation: RecordChangeOperation { }