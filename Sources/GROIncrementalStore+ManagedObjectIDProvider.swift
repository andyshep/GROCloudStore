//
//  GROIncrementalStore+ManagedObjectIDProvider.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 6/16/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CoreData

extension GROIncrementalStore: ManagedObjectIDProvider {
    
    /**
     Find the `NSManagedObjectID` that matches the entity and identifier. The object id returned
     is attached to the main context
     
     - parameter entity: Entity
     - parameter with identifier: String
     
     - returns: NSManagedObjectID assocated with the entity and identifier
     */
    
    internal func objectID(for entity: NSEntityDescription, with identifier: String?) throws -> NSManagedObjectID {
        guard let identifier = identifier else { throw GROIncrementalStoreError.noRemoteIdentifier }
        guard let name = entity.name else { throw GROIncrementalStoreError.noEntityName }
        
        let cachedObjectIdentifier = GROAttribute.prefix + String(identifier)
        
        var managedObjectId: NSManagedObjectID? = nil
        if let entities = self.registeredEntities[name] {
            if let objectId = entities[String(identifier)] {
                managedObjectId = objectId
            }
        }
        
        if managedObjectId == nil {
            guard let context = self.mainContext else { fatalError() }
            
            context.performAndWait {
                for object in context.registeredObjects {
                    let refObj = self.referenceObject(for: object.objectID)
                    if identifier as String == resourceIdentifier(refObj as AnyObject) {
                        managedObjectId = object.objectID
                        break
                    }
                }
            }
        }
        
        if managedObjectId == nil {
            managedObjectId = newObjectID(for: entity, referenceObject: cachedObjectIdentifier)
        }
        
        guard let _ = managedObjectId else { throw GROIncrementalStoreError.objectIdNotFound }
        
        var entities = self.registeredEntities[name] ?? [:]
        entities[String(identifier)] = managedObjectId!
        self.registeredEntities[name] = entities
        
        return managedObjectId!
    }
    
    internal func backingObjectID(for entity: NSEntityDescription, with identifier: String?) throws -> NSManagedObjectID? {
        guard let identifier = identifier else { throw GROIncrementalStoreError.noRemoteIdentifier }
        guard let name = entity.name else { throw GROIncrementalStoreError.noEntityName }
        
        let fetchRequest = NSFetchRequest<NSManagedObjectID>(entityName: name)
        fetchRequest.resultType = .managedObjectIDResultType
        fetchRequest.fetchLimit = 1
        
        let predicate = NSPredicate(format: "%K = %@", GROAttribute.resourceIdentifier, identifier)
        fetchRequest.predicate = predicate
        
        var backingObjectId: NSManagedObjectID?
        if let entities = self.registeredBackingEntities[name] {
            if let objectId = entities[String(identifier)] {
                backingObjectId = objectId
            }
        }
        
        if backingObjectId == nil {
            var fetchError: Error?
            
            self.backingContext.performAndWait {
                do {
                    let results = try self.backingContext.fetch(fetchRequest)
                    backingObjectId = results.last
                } catch (let error) {
                    fetchError = error
                }
            }
            
            guard fetchError == nil else { throw GROIncrementalStoreError.fetchError(fetchError!) }
            
            if backingObjectId != nil {
                var entities = self.registeredBackingEntities[name] ?? [:]
                entities[String(identifier)] = backingObjectId!
                self.registeredBackingEntities[name] = entities
            }
        }
        
        return backingObjectId
    }
    
    internal func entity(for identifier: String, in context: NSManagedObjectContext) -> NSEntityDescription? {
        for (name, identifiers) in self.registeredEntities {
            for (id, _) in identifiers {
                if id == identifier {
                    let entity = NSEntityDescription.entity(forEntityName: name, in: context)
                    return entity
                }
            }
        }
        
        for (name, identifiers) in self.registeredBackingEntities {
            for (id, _) in identifiers {
                if id == identifier {
                    let entity = NSEntityDescription.entity(forEntityName: name, in: context)
                    return entity
                }
            }
        }
        
        print("warning: missing entity for identifier: \(identifier)")
        
        return nil
    }
    
    internal func register(objectID: NSManagedObjectID, for identifier: String, in context: NSManagedObjectContext) {
        guard let name = objectID.entity.name else { return }
        
        if context == self.backingContext {
            var entities = self.registeredBackingEntities[name] ?? [:]
            entities[String(identifier)] = objectID
            self.registeredBackingEntities[name] = entities
        }
        else {
            var entities = self.registeredEntities[name] ?? [:]
            entities[String(identifier)] = objectID
            self.registeredEntities[name] = entities
        }
    }
}
