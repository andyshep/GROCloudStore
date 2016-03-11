//
//  NameableEntity.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/8/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CloudKit
import CoreData

protocol NameableEntity {
    var entityName: String { get }
}

extension CKRecord: NameableEntity {
    var entityName: String {
        return self.recordType
    }
}

extension NSManagedObject: NameableEntity {
    var entityName: String {
        return self.entity.name ?? ""
    }
}