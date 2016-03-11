//
//  NSManagedObjectContext+Helpers.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/8/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CoreData

extension NSManagedObjectContext {
    func existingOrNewObjectForId(objectID: NSManagedObjectID?, entityName: String) throws -> NSManagedObject {
        do {
            if let objectID = objectID {
                return try self.existingObjectWithID(objectID)
            } else {
                let object = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: self)
                try object.managedObjectContext?.obtainPermanentIDsForObjects([object])
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
        }
    }
}