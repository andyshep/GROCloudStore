//
//  ContextOperation.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 3/11/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import Foundation
import CoreData

internal protocol ContextOperation: class {
    var request: NSPersistentStoreRequest { get }
    var context: NSManagedObjectContext { get }
    var backingContext: NSManagedObjectContext { get }
}
