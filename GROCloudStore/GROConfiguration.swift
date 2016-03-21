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
    var Identifier: String { get }
    var CustomZoneName: String { get }
}

public protocol SubscriptionType {
    var Default: [CKSubscription] { get }
}

public protocol Configuration {
    var CloudContainer: CloudContainerType { get }
    var Subscriptions: SubscriptionType { get }
}

struct DefaultContainer: CloudContainerType {
    var Identifier: String {
        return "iCloud.org.andyshep.GrowJo"
    }
    
    var CustomZoneName: String {
        return "zone1"
    }
}

struct Subscription: SubscriptionType {
    static let PlantChanges = "org.andyshep.GrowJo.subscription.plant.changes"
    
    var Default: [CKSubscription] {
        let subscriptionId = Subscription.PlantChanges
        let zoneId = CKRecordZoneID(zoneName: DefaultContainer().CustomZoneName, ownerName: CKOwnerDefaultName)
        
        let options = CKSubscriptionOptions.FiresOnRecordCreation
        let subscription = CKSubscription(recordType: "GROPlant", predicate: NSPredicate(format: "TRUEPREDICATE"), subscriptionID: subscriptionId, options: options)
        subscription.zoneID = zoneId
        
        let notificationInfo = CKNotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.soundName = ""
        subscription.notificationInfo = notificationInfo
        
        return [subscription]
    }
}

class GRODefaultConfiguration: Configuration {
    
    var Subscriptions: SubscriptionType {
        return Subscription()
    }
    
    var CloudContainer: CloudContainerType {
        return DefaultContainer()
    }
}
