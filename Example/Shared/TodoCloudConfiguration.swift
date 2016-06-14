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
    static let Todo = "iCloud.org.andyshep.example.Todos.subscription.Todo"
    
    var Default: [CKSubscription] {
        let subscriptionId = Subscription.Todo
        let zoneId = CKRecordZoneID(zoneName: DefaultContainer().CustomZoneName, ownerName: CKOwnerDefaultName)
        
        let options = CKSubscriptionOptions.firesOnRecordCreation
        let subscription = CKSubscription(recordType: "Todo", predicate: Predicate(format: "TRUEPREDICATE"), subscriptionID: subscriptionId, options: options)
        subscription.zoneID = zoneId
        
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
