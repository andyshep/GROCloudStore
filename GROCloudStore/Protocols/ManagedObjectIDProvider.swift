//
//  ManagedObjectIDProvider.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/8/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CoreData

protocol ManagedObjectIDProvider: class {
    func objectIDForEntity(entity: NSEntityDescription, identifier: NSString?) throws -> NSManagedObjectID
    func backingObjectIDForEntity(entity: NSEntityDescription, identifier: NSString?) throws -> NSManagedObjectID?
    
    func entityForIdentifier(identifier: String, context: NSManagedObjectContext) -> NSEntityDescription?
    func registerObjectID(objectID: NSManagedObjectID, forIdentifier identifier: String, context: NSManagedObjectContext)
}