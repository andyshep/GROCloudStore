//
//  TodoCloudConfiguration.swift
//  Todos
//
//  Created by Andrew Shepard on 5/23/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import Foundation
import GROCloudStore

struct DefaultContainer: CloudContainerType {
    var Identifier: String {
        return "iCloud.org.andyshep.example.Todos"
    }
    
    var CustomZoneName: String {
        return "examplezonename"
    }
}

struct Subscription: SubscriptionType {
    var Default: [CKSubscription] {
        return []
    }
}

class TodoCloudConfiguration: Configuration {
    var Subscriptions: SubscriptionType {
        return Subscription()
    }
    
    var CloudContainer: CloudContainerType {
        return DefaultContainer()
    }
}