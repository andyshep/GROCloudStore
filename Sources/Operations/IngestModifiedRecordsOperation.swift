//
//  IngestModifiedRecordsOperation.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/8/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CoreData
import CloudKit

final internal class IngestModifiedRecordsOperation: Operation {
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
        if let _ = self.operation.request as? NSSaveChangesRequest {
            return records.filter { $0.recordType != "" }
        }
        else if let fetchReq = self.operation.request as? NSFetchRequest<NSManagedObject> {
            return records.filter { $0.recordType != fetchReq.entityName }
        }
        else {
            return []
        }
    }
    
    private var primaryRecords: [CKRecord] {
        if let _ = self.operation.request as? NSSaveChangesRequest {
            return records.filter { $0.recordType == "" }
        }
        else if let fetchReq = self.operation.request as? NSFetchRequest<NSManagedObject> {
            return records.filter { $0.recordType == fetchReq.entityName }
        }
        else {
            return []
        }
    }
    
    override func main() {
        if self.records.count == 0 { return }
        
        let semaphore = DispatchSemaphore(value: 0)
        
        processRecords(on: context, using: semaphore)
        
        semaphore.wait()
        
        processRecords(on: backingContext)
    }
    
    private func processRecords(on context: NSManagedObjectContext, using lock: DispatchSemaphore? = nil) {
        context.performAndWait {
            for record in self.primaryRecords {
                self.updateObject(matching: record, in: context)
            }
            
            for record in self.secondaryRecords {
                self.updateObject(matching: record, in: context)
            }
                        
            lock?.signal()
        }
    }
    
    private func updateObject(matching record: CKRecord, in context: NSManagedObjectContext) {
        let identifier = record.recordID.recordName
        let entityName = record.entityName
        
        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else { fatalError("missing entity") }
        
        do {
            let objectId = try self.objectID(matching: identifier, description: entity, in: context)
            let object = try context.existingOrNewObjectForId(objectId, entityName: entityName)
            
            if objectId == nil {
                self.delegate?.register(objectID: object.objectID, for: identifier, in: context)
            }
            
            if context == self.backingContext {
                object.setValue(identifier, forKey: GROAttribute.resourceIdentifier)
                object.setValue(Date(), forKey: GROAttribute.lastModified)
            }
            
            guard let transformableObject = object as? CloudKitTransformable else { fatalError("wrong object type") }
            transformableObject.transform(record: record)
            
            let references = transformableObject.references(for: record)
            for (reference, key) in references {
                
                let identifier = reference.recordID.recordName
                guard let entity = self.delegate?.entity(for: identifier, in: context) else { fatalError("missing entity") }
                guard let referenceObjectID = try self.objectID(matching: identifier, description: entity, in: context) else { fatalError("missing object id") }
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
    
    private func objectID(matching identifier: String, description entity: NSEntityDescription, in context: NSManagedObjectContext) throws -> NSManagedObjectID? {
        
        if context == self.backingContext {
            let objectId = try self.delegate?.backingObjectID(for: entity, with: identifier)
            return objectId
        } else {
            let objectId = try self.delegate?.objectID(for: entity, with: identifier)
            return objectId
        }
    }
}
