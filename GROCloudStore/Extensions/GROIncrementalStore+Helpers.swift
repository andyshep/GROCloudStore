//
//  GROIncrementalStore+Helpers.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 3/10/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CoreData

struct Attribute {
    static var ResourceIdentifier: String {
        return  "__gro__resourceIdentifier"
    }
    
    static var LastModified: String {
        return "__gro__lastModified"
    }
    
    static var NeedsDeletion: String {
        return "__gro__needsDeletion"
    }
    
    static var Prefix: String {
        return "__gro__"
    }
}


protocol GROBackingStoreResourceType {
    var GROResourceIdentifier: String { get set }
    var GROLastModified: Date { get set }
}

extension NSManagedObject: GROBackingStoreResourceType {
    var GROResourceIdentifier: String {
        get {
            return self.value(forKey: Attribute.ResourceIdentifier) as? String ?? ""
        }
        set {
            self.setValue(newValue, forKey: Attribute.ResourceIdentifier)
        }
    }
    
    var GROLastModified: Date {
        get {
            return self.value(forKey: Attribute.LastModified) as? Date ?? Date()
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
        contentAttribute.attributeType = NSAttributeType.binaryDataAttributeType
        contentAttribute.isOptional = false
        contentAttribute.isIndexed = false
        
        return contentAttribute
    }
    
    class var zoneNameAttribute: NSAttributeDescription {
        let zoneNameAttribute = NSAttributeDescription()
        zoneNameAttribute.name = "zoneName"
        zoneNameAttribute.attributeType = NSAttributeType.stringAttributeType
        zoneNameAttribute.isOptional = true
        zoneNameAttribute.isIndexed = false
        
        return zoneNameAttribute
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
            resourceIdProperty.attributeType = .stringAttributeType
            resourceIdProperty.isIndexed = true
//            resourceIdProperty.isOptional = true
            
            let lastModifiedProperty = NSAttributeDescription()
            lastModifiedProperty.name = Attribute.LastModified
            lastModifiedProperty.attributeType = .dateAttributeType
            lastModifiedProperty.isIndexed = false
//            lastModifiedProperty.isOptional = true
            
            let needsDeletion = NSAttributeDescription()
            needsDeletion.name = Attribute.NeedsDeletion
            needsDeletion.attributeType = .booleanAttributeType
            needsDeletion.isIndexed = false
            needsDeletion.defaultValue = false
//            needsDeletion.isOptional = true
            
            var properties = entity.properties
            properties.append(resourceIdProperty)
            properties.append(lastModifiedProperty)
            properties.append(needsDeletion)
            
            entity.properties = properties
        }
        
        let changeTokenEntity = NSEntityDescription()
        changeTokenEntity.name = GROChangeToken.self.entityName
        changeTokenEntity.managedObjectClassName = String(describing: GROChangeToken.self)
        changeTokenEntity.properties = [NSAttributeDescription.contentAttribute, NSAttributeDescription.zoneNameAttribute]
        
        let recordZoneEntity = NSEntityDescription()
        recordZoneEntity.name = GRORecordZone.entityName
        recordZoneEntity.managedObjectClassName = String(describing: GRORecordZone.self)
        recordZoneEntity.properties = [NSAttributeDescription.contentAttribute]
        
        let subscriptionEntity = NSEntityDescription()
        subscriptionEntity.name = GROSubscription.entityName
        subscriptionEntity.managedObjectClassName = String(describing: GROSubscription.self)
        subscriptionEntity.properties = [NSAttributeDescription.contentAttribute]
        
        var entities = augmentedModel.entities
        entities.append(changeTokenEntity)
        entities.append(recordZoneEntity)
        entities.append(subscriptionEntity)
        
        augmentedModel.entities = entities
        
        return augmentedModel
    }
}

internal func resourceIdentifier(_ referenceObject: AnyObject) -> String {
    let refObj = String(referenceObject.description)
    let prefix = Attribute.Prefix
    
    if (refObj?.hasPrefix(prefix))! {
        let index = refObj?.index((refObj?.startIndex)!, offsetBy: prefix.characters.count)
        let identifier = refObj?.substring(from: index!)
        return identifier!
    }
    
    return refObj!
}

internal func uniqueStoreIdentifier() -> String {
    guard let token = FileManager.default.ubiquityIdentityToken else {
        return GROIncrementalStore.storeType
    }
    
    var identifier = String(describing: token)
    
    identifier = identifier.replacingOccurrences(of: "<", with: "")
    identifier = identifier.replacingOccurrences(of: ">", with: "")
    identifier = identifier.replacingOccurrences(of: " ", with: "-")
    
    return identifier
}
