//
//  GROConfiguration.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/10/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import Foundation
import CloudKit

/**
 Describes the CloudKit container a client uses to save data.
 */
public protocol CloudContainerType {
    
    /// Identifier represents the CloudKit container identifier used by the client.
    var Identifier: String { get }
    
    /// An array of `CKRecordZone` names used to store records.
    var CustomZoneNames: [String] { get }
    
    /// A dictionary to maps record types to `CKRecordZone` names.
    var ZoneToRecordMappings: [String: String] { get }
}

/**
 Describes a CloudKit subscription.
 */
public protocol SubscriptionType {
    
    /// The set of `CKSubscription` objects used by the client.
    var Default: [CKSubscription] { get }
}

/**
 Describes a CloudKit configuration used to store data. Contains references to the CloudKit container type, custom records zones, and any subscription ids used.
 */
public protocol Configuration {
    
    /// Describes the CloudKit container used by the client.
    var CloudContainer: CloudContainerType { get }
    
    /// Describes the CloudKit subscriptons used by the client.
    var Subscriptions: SubscriptionType { get }
}

internal extension CloudContainerType {
    func zoneName(forRecordType type: String) -> String {
        guard let name = ZoneToRecordMappings[type] else {
            print("warning: missing zone name for type: \(type)")
            return CustomZoneNames.first ?? ""
        }
        
        return name
    }
}
