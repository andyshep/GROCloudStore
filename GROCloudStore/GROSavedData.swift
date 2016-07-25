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
}

extension NSManagedObject {
    class var entityName: String {
        return String(describing: self)
    }
    
    class func newObject(in context: NSManagedObjectContext) -> NSManagedObject {
        let name = self.entityName
        let object = NSEntityDescription.insertNewObject(forEntityName: name, into: context)
        return object
    }
}

@objc(GRORecordZone)
class GRORecordZone: GROSavedData { }

@objc(GROSubscription)
class GROSubscription: GROSavedData { }
