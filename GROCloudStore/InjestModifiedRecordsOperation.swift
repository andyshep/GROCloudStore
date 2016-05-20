//
//  InjestModifiedRecordsOperation.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/8/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CoreData
import CloudKit

class InjestModifiedRecordsOperation: NSOperation {
    unowned var operation: RecordChangeOperation
    weak var delegate: ManagedObjectIDProvider?
    
    required init(operation: RecordChangeOperation) {
        self.operation = operation
        super.init()
    }
    
    var context: NSManagedObjectContext {
        return self.operation.context
    }
    
    var backingContext: NSManagedObjectContext {
        return self.operation.backingContext
    }
    
    private var records: [CKRecord] {
        return operation.updatedRecords + operation.insertedRecords
    }
    
    private var secondaryRecords: [CKRecord] {
        return records.filter { $0.recordType != operation.request.recordType }
    }
    
    private var primaryRecords: [CKRecord] {
        return records.filter { $0.recordType == operation.request.recordType }
    }
    
    override func main() {
        if self.records.count == 0 { return }
        
        processRecordsOnContext(context)
        processRecordsOnContext(backingContext)
    }
    
    private func processRecordsOnContext(context: NSManagedObjectContext) {
        context.performBlockAndWait {
            for record in self.primaryRecords {
                self.updateRecord(record, context: context)
            }
            
            for record in self.secondaryRecords {
                self.updateRecord(record, context: context)
            }
        }
    }
    
    private func updateRecord(record: CKRecord, context: NSManagedObjectContext) {
        let identifier = record.recordID.recordName
        let entityName = record.entityName
        
        guard let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: context) else { fatalError("missing entity") }
        
        do {
            let objectId = try self.objectIDMatching(identifier, entity, context)
            let object = try context.existingOrNewObjectForId(objectId, entityName: entityName)
            
            if objectId == nil {
                self.delegate?.registerObjectID(object.objectID, forIdentifier: identifier, context: context)
            }
            
            if context == self.backingContext {
                object.setValue(identifier, forKey: Attribute.ResourceIdentifier)
                object.setValue(NSDate(), forKey: Attribute.LastModified)
            }
            
            guard let transformableObject = object as? CloudKitTransformable else { fatalError("wrong object type") }
            transformableObject.transform(record: record)
            
            let references = transformableObject.references(record)
            for (reference, key) in references {
                
                let identifier = reference.recordID.recordName
                guard let entity = self.delegate?.entityForIdentifier(identifier, context: context) else { fatalError("missing entity") }
                guard let referenceObjectID = try self.objectIDMatching(identifier, entity, context) else { fatalError("missing object id") }
                let referenceObject = try context.existingObjectWithID(referenceObjectID)
                
                guard let relationship = object.entity.relationshipsByName[key] else { fatalError("relationship not found") }
                
                if !relationship.toMany {
                    object.setValue(referenceObject, forKey: key)
                } else {
                    // Relationships are hooked up in reverse.
                    print("warning: unhandled \"to many\" relationship: \(relationship)")
                }
            }
            
        } catch {
            fatalError("main object not found: \(error)")
        }
    }
    
    private func objectIDMatching(identifier: String, _ entity: NSEntityDescription, _ context: NSManagedObjectContext) throws -> NSManagedObjectID? {
        
        if context == self.backingContext {
            let objectId = try self.delegate?.backingObjectIDForEntity(entity, identifier: identifier)
            return objectId
        } else {
            let objectId = try self.delegate?.objectIDForEntity(entity, identifier: identifier)
            return objectId
        }
    }
}