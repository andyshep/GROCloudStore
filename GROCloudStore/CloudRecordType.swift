//
//  CloudAndCoreDataTypes.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/9/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import Foundation
import CoreData

protocol CloudRecordType {
    var recordType: String { get }
}

extension NSFetchRequest {
    override var recordType: String {
        return self.entityName ?? ""
    }
}

extension NSPersistentStoreRequest: CloudRecordType {
    var recordType: String {
        return ""
    }
}