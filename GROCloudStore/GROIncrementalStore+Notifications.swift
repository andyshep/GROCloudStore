//
//  GROIncrementalStore+Notifications.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 6/16/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import Foundation

internal extension NSNotification.Name {
    static let GROCloudKitAccountChanged = NSNotification.Name.init("GROCloudKitAccountChanged")
    static let GROCloudKitNotAvailable = NSNotification.Name.init("GROCloudKitNotAvailable")
}

internal extension GROIncrementalStore {
    internal func contextDidChange(_ notification: Notification) {
        guard let context = notification.object as? NSManagedObjectContext else { return }
        let contextSaveInfo = (notification as NSNotification).userInfo ?? [:]
        
        if context == self.backingContext {
            guard let mergeContext = self.mainContext else { return }
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: contextSaveInfo, into: [mergeContext])
        }
        else if context == self.mainContext {
            let mergeContext = self.backingContext
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: contextSaveInfo, into: [mergeContext])
            
            self.backingContext.perform({
                self.backingContext.saveOrLogError()
            })
        }
    }
    
    internal func didCreateRecord(_ notification: Notification) {
        guard let objectID = (notification as NSNotification).userInfo?[GROObjectIDKey] as? NSManagedObjectID else { return }
        guard let identifier = (notification as NSNotification).userInfo?[GRORecordNameKey] as? String else { return }
        
        guard let name = objectID.entity.name else { return }
        
        var entities = self.registeredEntities[name] ?? [:]
        entities[identifier] = objectID
        self.registeredEntities[name] = entities
    }
    
    internal func cloudDidChange(_ notification: Notification) {
        let token = FileManager.default.ubiquityIdentityToken
        print("change token: \(String(describing: token))")
        
        DispatchQueue.main.async {
            let name = NSNotification.Name.GROCloudKitAccountChanged
            NotificationCenter.default.post(name: name, object: nil)
        }
    }
}
