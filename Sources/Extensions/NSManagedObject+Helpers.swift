//
//  NSManagedObject+Helpers.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 10/7/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CoreData

internal extension NSManagedObject {
    class var entityName: String {
        return String(describing: self)
    }
    
    class func newObject(in context: NSManagedObjectContext) -> NSManagedObject {
        let name = self.entityName
        let object = NSEntityDescription.insertNewObject(forEntityName: name, into: context)
        return object
    }
}
