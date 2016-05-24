//
//  VerifyRecordZoneOperation.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/17/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CoreData
import CloudKit

typealias Zones = [CKRecordZoneID: CKRecordZone]

class VerifyRecordZoneOperation: AsyncOperation {
    
    private let context: NSManagedObjectContext
    private let dataSource: CloudDataSource
    
    init(context: NSManagedObjectContext, dataSource: CloudDataSource) {
        self.context = context
        self.dataSource = dataSource
        super.init()
    }
    
    override func main() {
        var shouldCreateZone = true
        
        self.context.performBlockAndWait { 
            do {
                let request = NSFetchRequest(entityName: GRORecordZone.entityName)
                let results = try self.context.executeFetchRequest(request)
                if let _ = results.first as? GRORecordZone {
                    shouldCreateZone = false
                }
            }
            catch {
                //
            }
        }
        
        if shouldCreateZone {
            dataSource.fetchRecordsZones(didFetchRecordZones)
        }
        else {
            print("zone verified, skipping creation")
            finish()
        }
    }
    
    private func didFetchRecordZones(zones: Zones?, error: NSError?) {
        guard error == nil else { fatalError() }
        guard let zones = zones else { return finish() }
        
        var found = false
        let configuration = self.dataSource.configuration
        let defaultZoneID = CKRecordZoneID(zoneName: configuration.CloudContainer.CustomZoneName, ownerName: CKOwnerDefaultName)
        
        for (zoneId, _) in zones {
            if zoneId == defaultZoneID {
                found = true
                break
            }
        }
        
        if found {
            saveRecordZoneID(defaultZoneID, context: self.context)
            finish()
        }
        else {
            let configuration = dataSource.configuration
            self.dataSource.createRecordZone(configuration.CloudContainer.CustomZoneName, completion: didCreateRecordZone)
        }
    }
    
    private func didCreateRecordZone(recordZone: CKRecordZone?, error: NSError?) {
        finish()
    }
    
    private func saveRecordZoneID(recordZoneID: CKRecordZoneID, context: NSManagedObjectContext) {
        context.performBlock { 
            guard let savedZone = GRORecordZone.newObjectInContext(context) as? GRORecordZone else { return }
            
            savedZone.content = NSKeyedArchiver.archivedDataWithRootObject(recordZoneID)
            context.saveOrLogError()
        }
    }
}
