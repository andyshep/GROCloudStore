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
    
    var CustomZoneNames: [String] {
        return ["examplezonename"]
    }
    
    var ZoneToRecordMappings: [String : String] {
        return ["Todo": "examplezonename"]
    }
}

public struct Subscription: SubscriptionType {
    public static let Todo = "iCloud.org.andyshep.example.Todos.subscription.Todo"
    
    public var Default: [CKSubscription] {
        let subscription = CKDatabaseSubscription(subscriptionID: Subscription.Todo)
        
        let notificationInfo = CKNotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        return [subscription]
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
