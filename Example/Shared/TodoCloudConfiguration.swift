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
    var identifier: String {
        return "iCloud.org.andyshep.example.Todos"
    }
    
    var customZoneNames: [String] {
        return ["examplezonename"]
    }
    
    var zoneToRecordMappings: [String : String] {
        return ["Todo": "examplezonename"]
    }
}

public struct Subscription: SubscriptionType {
    public enum Name: String {
        case Todo = "iCloud.org.andyshep.example.Todos.subscription.Todo"
    }
    
    public var all: [CKSubscription] {
        let subscription = CKDatabaseSubscription(subscriptionID: Name.Todo.rawValue)
        
        let notificationInfo = CKNotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        return [subscription]
    }
}

class TodoCloudConfiguration: Configuration {
    var subscriptions: SubscriptionType {
        return Subscription()
    }
    
    var container: CloudContainerType {
        return DefaultContainer()
    }
}
