//
//  NSManagedObjectContext+Helpers.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/8/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CoreData

public extension NSManagedObjectContext {
    func existingOrNewObjectForId(_ objectID: NSManagedObjectID?, entityName: String) throws -> NSManagedObject {
        do {
            if let objectID = objectID {
                return try self.existingObject(with: objectID)
            } else {
                let object = NSEntityDescription.insertNewObject(forEntityName: entityName, into: self)
                try object.managedObjectContext?.obtainPermanentIDs(for: [object])
                return object
            }
        } catch { throw error }
    }
    
    func saveOrLogError() -> Void {
        if hasChanges {
            do { try self.save() }
            catch {
                print("error saving context: \(error)")
            }
        } else {
            print("no changes")
        }
    }
}
