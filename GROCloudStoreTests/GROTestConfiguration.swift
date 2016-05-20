//
//  GROTestConfiguration.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 5/20/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import Foundation
import CloudKit

struct DefaultTestContainer: CloudContainerType {
    var Identifier: String {
        return "iCloud.org.andyshep.GROCloudStore"
    }
    
    var CustomZoneName: String {
        return "zone1"
    }
}

struct TestSubscription: SubscriptionType {
    static let TestSubscriptionName = "org.andyshep.GROCloudStore.TestSubscription"
    
    var Default: [CKSubscription] {
        let subscriptionId = TestSubscription.TestSubscriptionName
        let zoneId = CKRecordZoneID(zoneName: DefaultTestContainer().CustomZoneName, ownerName: CKOwnerDefaultName)
        
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

class GROTestConfiguration: NSObject {
    
}

extension GROTestConfiguration: Configuration {
    var Subscriptions: SubscriptionType {
        return TestSubscription()
    }
    
    var CloudContainer: CloudContainerType {
        return DefaultTestContainer()
    }
}