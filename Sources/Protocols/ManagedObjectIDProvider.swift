//
//  ManagedObjectIDProvider.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/8/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CoreData

protocol ManagedObjectIDProvider: class {
    func objectID(for entity: NSEntityDescription, with identifier: String?) throws -> NSManagedObjectID
    func backingObjectID(for entity: NSEntityDescription, with identifier: String?) throws -> NSManagedObjectID?
    
    func entity(for indentifier: String, in context: NSManagedObjectContext) -> NSEntityDescription?
    func register(objectID: NSManagedObjectID, for indentifier: String, in context: NSManagedObjectContext)
}
