//
//  CKAccountStatus+Available.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 6/16/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CloudKit

internal extension CKAccountStatus {
    var isAvailable: Bool {
        switch self {
        case .available:
            return true
        default:
            return false
        }
    }
}
