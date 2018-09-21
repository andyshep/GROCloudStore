//
//  VerifyRecordZoneOperation.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/17/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CoreData
import CloudKit

typealias Zones = [CKRecordZone.ID: CKRecordZone]

final internal class VerifyRecordZoneOperation: AsyncOperation {
    
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
            } catch {
                //
            }
        }
        
        if shouldCreateZone {
            dataSource.fetchRecordsZones(completion: didFetch)
        } else {
            print("zone verified, skipping creation")
            finish()
        }
    }
    
    private func didFetch(recordZones zones: Zones?, error: Error?) {
        guard error == nil else { attemptCloudKitRecoveryFrom(error: error!); return finish() }
        guard let zones = zones else { return finish() }
        
        var found = false
        let configuration = self.dataSource.configuration
        
        let zoneName = configuration.container.customZoneNames.first!
        let defaultZoneID = CKRecordZone.ID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)
        
        for (zoneId, _) in zones {
            if zoneId == defaultZoneID {
                found = true
                break
            }
        }
        
        if found {
            save(recordZoneID: defaultZoneID, in: context)
            finish()
        }
        else {
            self.dataSource.createRecordZone(name: zoneName, completion: didCreate)
        }
        
        finish()
    }
    
    private func didCreate(recordZone: CKRecordZone?, error: Error?) {
        finish()
    }
    
    private func save(recordZoneID: CKRecordZone.ID, in context: NSManagedObjectContext) {
        context.perform { 
            guard let savedZone = GRORecordZone.newObject(in: context) as? GRORecordZone else { return }
            
            savedZone.content = NSKeyedArchiver.archivedData(withRootObject: recordZoneID)
            context.saveOrLogError()
        }
    }
}
