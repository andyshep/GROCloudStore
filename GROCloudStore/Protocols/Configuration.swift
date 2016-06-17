//
//  GROConfiguration.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/10/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import Foundation
import CloudKit

public protocol CloudContainerType {
    // container identifier
    var Identifier: String { get }
    
    // custom zone name
    var CustomZoneName: String { get }
}

public protocol SubscriptionType {
    // set of subscriptions
    var Default: [CKSubscription] { get }
}

public protocol Configuration {
    var CloudContainer: CloudContainerType { get }
    var Subscriptions: SubscriptionType { get }
}
