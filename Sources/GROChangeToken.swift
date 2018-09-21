//
//  GROChangeToken.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 6/22/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CoreData
import CloudKit

@objc(GROChangeToken)
internal class GROChangeToken: NSManagedObject {
    @NSManaged var content: Data
    @NSManaged var zoneName: String?
}

internal func changeTokens(forZoneIds zoneIds: [CKRecordZone.ID], in context: NSManagedObjectContext) -> [CKRecordZone.ID: CKServerChangeToken]? {
    let request = NSFetchRequest<GROChangeToken>(entityName: GROChangeToken.entityName)
    do {
        let zoneNames = zoneIds.map { return $0.zoneName }
        let results = try context.fetch(request)
        let savedChanges = results.filter { return zoneNames.contains($0.zoneName!) }
        
        var tokens: [CKRecordZone.ID: CKServerChangeToken] = [:]
        
        for change in savedChanges {
            let zoneName = change.zoneName
            let zoneId = CKRecordZone.ID(zoneName: zoneName!, ownerName: CKCurrentUserDefaultName)
            
            if let token = NSKeyedUnarchiver.unarchiveObject(with: change.content) as? CKServerChangeToken {
                tokens[zoneId] = token
            }
        }
        
        return tokens.count > 0 ? tokens : nil
    } catch {
        fatalError("error fetching change tokens: \(error)")
    }
}

internal func changeToken(forRecordZoneId zoneId: CKRecordZone.ID, in context: NSManagedObjectContext) -> GROChangeToken {
    if let tokens = existingChangeTokens(in: context) {
        let matches = tokens.filter { return $0.zoneName == zoneId.zoneName }
        
        if let token = matches.first {
            return token
        }
    }
    
    return newChangeToken(in: context)
}

internal func existingChangeTokens(in context: NSManagedObjectContext) -> [GROChangeToken]? {
    let request = NSFetchRequest<GROChangeToken>(entityName: GROChangeToken.entityName)
    do {
        return try context.fetch(request)
    }
    catch {
        print("unhandled error: \(error)")
    }
    
    return nil
}

internal func newChangeToken(in context: NSManagedObjectContext) -> GROChangeToken {
    let object = GROChangeToken.newObject(in: context)
    guard let token = object as? GROChangeToken else {
        fatalError()
    }
    
    return token
}

internal func save(token: CKServerChangeToken?, forRecordZoneId zoneId: CKRecordZone.ID, in context: NSManagedObjectContext) {
    if let token = token {
        context.performAndWait {
            let savedChangeToken = changeToken(forRecordZoneId: zoneId, in: context)
            savedChangeToken.content = NSKeyedArchiver.archivedData(withRootObject: token)
            savedChangeToken.zoneName = zoneId.zoneName
            context.saveOrLogError()
        }
    }
}

internal func databaseChangeToken(in context: NSManagedObjectContext) -> CKServerChangeToken? {
    let request = NSFetchRequest<GROChangeToken>(entityName: GROChangeToken.entityName)
    do {
        let results = try context.fetch(request)
        let matches = results.filter { return $0.zoneName == "" }
        guard let match = matches.first else { return nil }
        guard let token = NSKeyedUnarchiver.unarchiveObject(with: match.content) as? CKServerChangeToken else { return nil }
        
        return token
    }
    catch {
        print("error fetching change token: \(error)")
        return nil
    }
}
