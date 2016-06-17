//
//  DatabaseChangesOperation.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 6/22/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CloudKit
import CoreData

class DatabaseChangesOperation: AsyncOperation {
    let context: NSManagedObjectContext
//    let request: NSPersistentStoreRequest
    
    private(set) var changedRecordZoneIds: [CKRecordZoneID] = []
    private(set) var deletedRecordZoneIds: [CKRecordZoneID] = []
    
    let dataSource: CloudDataSource
    
    required init(context: NSManagedObjectContext, dataSource: CloudDataSource) {
//        self.request = request
//        self.context = context
        self.context = context
        self.dataSource = dataSource
        
        super.init()
    }
    
    override func main() {
        let token = databaseChangeToken(in: context)
        
        dataSource.changes(since: token) { [unowned self] (changed, deleted, token) in
            
            // TODO: save token
            print("TODO save database token: \(token)")
            
            for changedZone in changed {
                self.changedRecordZoneIds.append(changedZone)
            }
            
            for deletedZone in deleted {
                self.deletedRecordZoneIds.append(deletedZone)
            }
            
            self.finish()
        }
    }
}
