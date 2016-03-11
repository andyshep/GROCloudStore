//
//  GROConfiguration.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/10/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import Foundation
import CloudKit

struct Attribute {
    static let ResourceIdentifier = "__gro__resourceIdentifier"
    static let LastModified = "__gro__lastModified"
    static let NeedsDeletion = "__gro__needsDeletion"
    
    static let Prefix = "__gro__"
}

struct CloudContainer {
    static let Identifier = "iCloud.org.andyshep.GrowJo"
    
    struct ZoneNames {
        static let Custom = "zone1"
    }
    
    struct Subscriptions {
        static let PlantChanges = "org.andyshep.GrowJo.subscription.plant.changes"
    }
}

struct Key {
    static let ObjectID = "ObjectID"
    static let RecordName = "RecordName"
}

struct Subscriptions {
    static var Default: [CKSubscription] {
        let subscriptionId = CloudContainer.Subscriptions.PlantChanges
        let zoneId = CKRecordZoneID(zoneName: CloudContainer.ZoneNames.Custom, ownerName: CKOwnerDefaultName)
        
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