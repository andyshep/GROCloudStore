//
//  ManagedObjectIDProvider.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/8/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CoreData

protocol ManagedObjectIDProvider: class {
    func objectID(for entity: NSEntityDescription, identifier: NSString?) throws -> NSManagedObjectID
    func backingObjectID(for entity: NSEntityDescription, identifier: NSString?) throws -> NSManagedObjectID?
    
    func entity(for identifier: String, context: NSManagedObjectContext) -> NSEntityDescription?
    func register(_ objectID: NSManagedObjectID, for identifier: String, context: NSManagedObjectContext)
}