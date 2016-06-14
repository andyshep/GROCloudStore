//
//  GROSavedData.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 3/11/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CoreData

@objc(GROSavedData)
class GROSavedData: NSManagedObject {
    @NSManaged var content: Data
    
    class var entityName: String {
        return String(self)
    }
    
    class func newObject(in context: NSManagedObjectContext) -> NSManagedObject {
        let name = self.entityName
        let object = NSEntityDescription.insertNewObject(forEntityName: name, into: context)
        return object
    }
}

@objc(GROChangeToken)
class GROChangeToken: GROSavedData { }

@objc(GRORecordZone)
class GRORecordZone: GROSavedData { }

@objc(GROSubscription)
class GROSubscription: GROSavedData { }
