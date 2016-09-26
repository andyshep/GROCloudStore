//
//  ManagedObjectTransformable.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/25/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CoreData

@objc public protocol ManagedObjectTransformable {
    func transform(using object: NSManagedObject) -> Void
}
