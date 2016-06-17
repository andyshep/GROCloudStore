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
    // container identifier
    var Identifier: String { get }
    
    // custom zone name
    var CustomZoneNames: [String] { get }
    
    var ZoneToRecordMappings: [String: String] { get }
}

extension CloudContainerType {
    func zoneName(forRecordType type: String) -> String {
        guard let name = ZoneToRecordMappings[type] else {
            print("warning: missing zone name for type: \(type)")
            return CustomZoneNames.first ?? ""
        }
        
        return name
    }
}

public protocol SubscriptionType {
    // set of subscriptions
    var Default: [CKSubscription] { get }
}

public protocol Configuration {
    var CloudContainer: CloudContainerType { get }
    var Subscriptions: SubscriptionType { get }
}
