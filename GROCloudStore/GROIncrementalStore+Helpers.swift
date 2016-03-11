//
//  GROIncrementalStore+Helpers.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 3/10/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CoreData

protocol GROBackingStoreResourceType {
    var GROResourceIdentifier: String { get set }
    var GROLastModified: NSDate { get set }
}

extension NSManagedObject: GROBackingStoreResourceType {
    var GROResourceIdentifier: String {
        get {
            return self.valueForKey(Attribute.ResourceIdentifier) as? String ?? ""
        }
        set {
            self.setValue(newValue, forKey: Attribute.ResourceIdentifier)
        }
    }
    
    var GROLastModified: NSDate {
        get {
            return self.valueForKey(Attribute.LastModified) as? NSDate ?? NSDate()
        }
        set {
            self.setValue(newValue, forKey: Attribute.LastModified)
        }
    }
}

extension NSAttributeDescription {
    class var contentAttribute: NSAttributeDescription {
        let contentAttribute = NSAttributeDescription()
        contentAttribute.name = "content"
        contentAttribute.attributeType = NSAttributeType.BinaryDataAttributeType
        contentAttribute.optional = false
        contentAttribute.indexed = false
        
        return contentAttribute
    }
}

extension NSManagedObjectModel {
    var GROAugmentedModel: NSManagedObjectModel {
        guard let augmentedModel = self.copy() as? NSManagedObjectModel else {
            fatalError("could not copy model")
        }
        
        for entity in augmentedModel.entities {
            if entity.superentity != nil { continue }
            
            let resourceIdProperty = NSAttributeDescription()
            resourceIdProperty.name = Attribute.ResourceIdentifier
            resourceIdProperty.attributeType = .StringAttributeType
            resourceIdProperty.indexed = true
            
            let lastModifiedProperty = NSAttributeDescription()
            lastModifiedProperty.name = Attribute.LastModified
            lastModifiedProperty.attributeType = .DateAttributeType
            lastModifiedProperty.indexed = false
            
            let needsDeletion = NSAttributeDescription()
            needsDeletion.name = Attribute.NeedsDeletion
            needsDeletion.attributeType = .BooleanAttributeType
            needsDeletion.indexed = false
            needsDeletion.defaultValue = false
            
            var properties = entity.properties
            properties.append(resourceIdProperty)
            properties.append(lastModifiedProperty)
            properties.append(needsDeletion)
            
            entity.properties = properties
        }
        
        let changeTokenEntity = NSEntityDescription()
        changeTokenEntity.name = GROChangeToken.self.entityName
        changeTokenEntity.managedObjectClassName = String(GROChangeToken)
        changeTokenEntity.properties = [NSAttributeDescription.contentAttribute]
        
        let recordZoneEntity = NSEntityDescription()
        recordZoneEntity.name = GRORecordZone.entityName
        recordZoneEntity.managedObjectClassName = String(GRORecordZone)
        recordZoneEntity.properties = [NSAttributeDescription.contentAttribute]
        
        let subscriptionEntity = NSEntityDescription()
        subscriptionEntity.name = GROSubscription.entityName
        subscriptionEntity.managedObjectClassName = String(GROSubscription)
        subscriptionEntity.properties = [NSAttributeDescription.contentAttribute]
        
        var entities = augmentedModel.entities
        entities.append(changeTokenEntity)
        entities.append(recordZoneEntity)
        entities.append(subscriptionEntity)
        
        augmentedModel.entities = entities
        
        return augmentedModel
    }
}