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
    var identifier: String {
        return "iCloud.org.andyshep.GROCloudStore"
    }
    
    var customZoneNames: [String] {
        return ["zone1"]
    }
    
    var zoneToRecordMappings: [String : String] {
        return [:]
    }
}

struct TestSubscription: SubscriptionType {
    static let TestSubscriptionName = "org.andyshep.GROCloudStore.TestSubscription"
    
    var all: [CKSubscription] {
        let subscriptionId = TestSubscription.TestSubscriptionName
        let zoneId = CKRecordZone.ID(zoneName: DefaultTestContainer().customZoneNames.first!, ownerName: CKCurrentUserDefaultName)
        
        let options = CKQuerySubscription.Options.firesOnRecordCreation
        let subscription = CKQuerySubscription(recordType: "GROTestEntity", predicate: NSPredicate(format: "TRUEPREDICATE"), subscriptionID: subscriptionId, options: options)
        subscription.zoneID = zoneId
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.soundName = ""
        subscription.notificationInfo = notificationInfo
        
        return [subscription]
    }
}

class GROTestConfiguration: NSObject {

}

extension GROTestConfiguration: Configuration {
    var subscriptions: SubscriptionType {
        return TestSubscription()
    }
    
    var container: CloudContainerType {
        return DefaultTestContainer()
    }
}
