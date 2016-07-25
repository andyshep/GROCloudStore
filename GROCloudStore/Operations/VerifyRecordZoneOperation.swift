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
        
        self.context.performAndWait { 
            do {
                let request = NSFetchRequest<GRORecordZone>(entityName: GRORecordZone.entityName)
                let results = try self.context.fetch(request)
                if let _ = results.first {
                    shouldCreateZone = false
                }
            }
            catch {
                //
            }
        }
        
        if shouldCreateZone {
            dataSource.fetchRecordsZones(completion: didFetchRecordZones)
        }
        else {
            print("zone verified, skipping creation")
            finish()
        }
    }
    
    private func didFetchRecordZones(_ zones: Zones?, error: Error?) {
        guard error == nil else { attemptCloudKitRecoveryFrom(error: error!); return finish() }
        guard let zones = zones else { return finish() }
        
        var found = false
        let configuration = self.dataSource.configuration
        
        let zoneName = configuration.CloudContainer.CustomZoneNames.first!
        let defaultZoneID = CKRecordZoneID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)
        
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
            self.dataSource.createRecordZone(name: zoneName, completion: didCreateRecordZone)
        }
        
        finish()
    }
    
    private func didCreateRecordZone(_ recordZone: CKRecordZone?, error: Error?) {
        finish()
    }
    
    private func saveRecordZoneID(_ recordZoneID: CKRecordZoneID, context: NSManagedObjectContext) {
        context.perform { 
            guard let savedZone = GRORecordZone.newObject(in: context) as? GRORecordZone else { return }
            
            savedZone.content = NSKeyedArchiver.archivedData(withRootObject: recordZoneID)
            context.saveOrLogError()
        }
    }
}
