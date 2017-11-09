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

@objc(GRORecordZone)
class GRORecordZone: GROSavedData { }

@objc(GROSubscription)
class GROSubscription: GROSavedData { }
