//
//  Todo+CoreDataProperties.swift
//  Todos
//
//  Created by Andrew Shepard on 5/23/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Todo {

    @NSManaged var created: Date?
    @NSManaged var item: String?
    
    @NSManaged var encodedSystemFields: Data?

}
