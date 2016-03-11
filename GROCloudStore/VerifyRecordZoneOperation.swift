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
    private let cloudDataSource = GROCloudDataSource()
    
    init(context: NSManagedObjectContext) {
        self.context = context
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
            cloudDataSource.fetchRecordsZones(didFetchRecordZones)
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
        let defaultZoneID = CKRecordZoneID(zoneName: CloudContainer.ZoneNames.Custom, ownerName: CKOwnerDefaultName)
        
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
            self.cloudDataSource.createRecordZone(CloudContainer.ZoneNames.Custom, completion: didCreateRecordZone)
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
