//
//  InjestModifiedRecordsOperation.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/8/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CoreData
import CloudKit

class InjestModifiedRecordsOperation: Operation {
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
    
    private func processRecordsOnContext(_ context: NSManagedObjectContext) {
        context.performAndWait {
            for record in self.primaryRecords {
                self.updateRecord(record, context: context)
            }
            
            for record in self.secondaryRecords {
                self.updateRecord(record, context: context)
            }
        }
    }
    
    private func updateRecord(_ record: CKRecord, context: NSManagedObjectContext) {
        let identifier = record.recordID.recordName
        let entityName = record.entityName
        
        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else { fatalError("missing entity") }
        
        do {
            let objectId = try self.objectIDMatching(identifier, entity, context)
            let object = try context.existingOrNewObjectForId(objectId, entityName: entityName)
            
            if objectId == nil {
                self.delegate?.register(object.objectID, for: identifier, context: context)
            }
            
            if context == self.backingContext {
                object.setValue(identifier, forKey: Attribute.ResourceIdentifier)
                object.setValue(Date(), forKey: Attribute.LastModified)
            }
            
            guard let transformableObject = object as? CloudKitTransformable else { fatalError("wrong object type") }
            transformableObject.transform(record: record)
            
            let references = transformableObject.references(record)
            for (reference, key) in references {
                
                let identifier = reference.recordID.recordName
                guard let entity = self.delegate?.entity(for: identifier, context: context) else { fatalError("missing entity") }
                guard let referenceObjectID = try self.objectIDMatching(identifier, entity, context) else { fatalError("missing object id") }
                let referenceObject = try context.existingObject(with: referenceObjectID)
                
                guard let relationship = object.entity.relationshipsByName[key] else { fatalError("relationship not found") }
                
                if !relationship.isToMany {
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
    
    private func objectIDMatching(_ identifier: String, _ entity: NSEntityDescription, _ context: NSManagedObjectContext) throws -> NSManagedObjectID? {
        
        if context == self.backingContext {
            let objectId = try self.delegate?.backingObjectID(for: entity, identifier: identifier)
            return objectId
        } else {
            let objectId = try self.delegate?.objectID(for: entity, identifier: identifier)
            return objectId
        }
    }
}
