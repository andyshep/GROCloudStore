//
//  ManagedObjectTransformable.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/25/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CoreData

@objc protocol ManagedObjectTransformable {
    func transform(object _: NSManagedObject) -> Void
}