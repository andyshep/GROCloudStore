//
//  RecordChangeOperation.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/25/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import Foundation
import CloudKit

internal protocol RecordChangeOperation: ContextOperation {
    var insertedRecords: [CKRecord] { get }
    var updatedRecords: [CKRecord] { get }
    var deletedRecordIDs: [CKRecord.ID] { get }
}
