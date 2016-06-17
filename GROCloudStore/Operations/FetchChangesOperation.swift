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
    
    private(set) var insertedRecords: [CKRecord] = []
    private(set) var updatedRecords: [CKRecord] = []
    private(set) var deletedRecordIDs: [CKRecordID] = []
    
    weak var delegate: ManagedObjectIDProvider?
    
    private let dataSource: CloudDataSource
    
    required init(request: NSFetchRequest<NSManagedObject>, context: NSManagedObjectContext, backingContext: NSManagedObjectContext, dataSource: CloudDataSource) {
        self.request = request
        self.context = context
        self.backingContext = backingContext
        self.dataSource = dataSource
        
        super.init()
    }
    
    override func main() {
        guard let request = self.request as? NSFetchRequest<NSManagedObject> else { fatalError() }
        let recordType = request.recordType
        
        var token: CKServerChangeToken? = nil
        if let tokenObj = existingChangeToken(in: backingContext) {
            if let lastToken = NSKeyedUnarchiver.unarchiveObject(with: tokenObj.content as Data) as? CKServerChangeToken {
                token = lastToken
            }
        }
        
        dataSource.changedRecords(ofType: recordType, token: token) { (changedRecords, deletedRecordIDs, token) in
            
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
    
    private func recordDidChange(_ record: CKRecord) -> Void {
        self.updatedRecords.append(record)
    }
    
    private func recordIDWasDeleted(_ recordID: CKRecordID) -> Void {
        self.deletedRecordIDs.append(recordID)
    }
    
    private func changeToken(in context: NSManagedObjectContext) -> GROChangeToken {
        if let token = self.existingChangeToken(in: context) {
            return token
        }
        
        return self.newChangeToken(in: context)
    }
    
    private func existingChangeToken(in context: NSManagedObjectContext) -> GROChangeToken? {
        let request = NSFetchRequest<GROChangeToken>(entityName: GROChangeToken.entityName)
        do {
            let result = try context.fetch(request)
            if let token = result.first {
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
    
    private func saveToken(_ token: CKServerChangeToken?) {
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
