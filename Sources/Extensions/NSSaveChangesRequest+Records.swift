//
//  NSSaveChangesRequest+Records.swift
//  GrowJo
//
//  Created by Andrew Shepard on 8/10/15.
//  Copyright © 2015 Andrew Shepard. All rights reserved.
//

import CoreData
import CloudKit

internal extension NSSaveChangesRequest {
    
    var insertedRecords: [CKRecord] {
        let objects = self.insertedObjects ?? []
        return objects.flatMap({ (object) -> CKRecord? in
            guard let transformable = object as? CloudKitTransformable else { return nil }
            return transformable.transform()
        })
    }
    
    var updatedRecords: [CKRecord] {
        let objects = self.updatedObjects ?? []
        return objects.flatMap({ (object) -> CKRecord? in
            guard let transformable = object as? CloudKitTransformable else { return nil }
            return transformable.transform()
        })
    }
    
    var deletedRecordIDs: [CKRecordID] {
        let objects = self.deletedObjects ?? []
        return objects.flatMap { (object) -> CKRecordID? in
            guard let transformable = object as? CloudKitTransformable else { return nil }
            return transformable.transform().recordID
        }
    }
}
