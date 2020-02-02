//
//  DatabaseChangesOperation.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 6/22/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CloudKit
import CoreData

final internal class DatabaseChangesOperation: AsyncOperation {
    let context: NSManagedObjectContext
    
    private(set) var changedRecordZoneIds: [CKRecordZone.ID] = []
    private(set) var deletedRecordZoneIds: [CKRecordZone.ID] = []
    
    let dataSource: CloudDataSource
    
    required init(context: NSManagedObjectContext, dataSource: CloudDataSource) {
        self.context = context
        self.dataSource = dataSource
        
        super.init()
    }
    
    override func main() {
        let token = databaseChangeToken(in: context)
        
        dataSource.changes(since: token) { [unowned self] (changed, deleted, token) in
            
            if let token = token {
                let savedToken = newChangeToken(in: self.context)
                savedToken.content = NSKeyedArchiver.archivedData(withRootObject: token)
                savedToken.zoneName = ""
                self.context.saveOrLogError()
            }
                
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
