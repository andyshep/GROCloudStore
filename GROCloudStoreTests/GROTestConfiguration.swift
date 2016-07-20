//
//  GROTestConfiguration.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 5/20/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import Foundation
import CloudKit
@testable import GROCloudStore

struct DefaultTestContainer: CloudContainerType {
    var Identifier: String {
        return "iCloud.org.andyshep.GROCloudStore"
    }
    
    var CustomZoneNames: [String] {
        return ["zone1"]
    }
    
    var ZoneToRecordMappings: [String : String] {
        return [:]
    }
}

struct TestSubscription: SubscriptionType {
    static let TestSubscriptionName = "org.andyshep.GROCloudStore.TestSubscription"
    
    var Default: [CKSubscription] {
        let subscriptionId = TestSubscription.TestSubscriptionName
        let zoneId = CKRecordZoneID(zoneName: DefaultTestContainer().CustomZoneNames.first!, ownerName: CKOwnerDefaultName)
        
        let options = CKSubscriptionOptions.firesOnRecordCreation
        let subscription = CKSubscription(recordType: "GROTestEntity", predicate: Predicate(format: "TRUEPREDICATE"), subscriptionID: subscriptionId, options: options)
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
