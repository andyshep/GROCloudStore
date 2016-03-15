//
//  CoreData+Extensions.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 11/13/15.
//  Copyright © 2015 Andrew Shepard. All rights reserved.
//

import Foundation
import CoreData

public func createInMemoryContext(model: NSManagedObjectModel) -> NSManagedObjectContext? {
    
    if let coordinator = NSPersistentStoreCoordinator.coordinatorWithInMemoryStoreUsingModel(model) {
        let context = NSManagedObjectContext.mainContextForCoordinator(coordinator)
        return context
    }
    else {
        return nil
    }
}

public func saveContext(context: NSManagedObjectContext) {
    if context.hasChanges {
        do {
            try context.save()
        }
        catch (let error as NSError) {
            fatalError("error saving context: \(error)")
        }
    }
}

extension NSPersistentStoreCoordinator {
    public static func coordinatorWithInMemoryStoreUsingModel(model: NSManagedObjectModel) -> NSPersistentStoreCoordinator? {
        do {
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
            let dataSource = GROTestDataSource()
            let configuration = GRODefaultConfiguration()
            
            let options: [NSObject: AnyObject] = [GRODataSourceKey: dataSource, GROUseInMemoryStoreKey: NSNumber(bool: true), GROConfigurationKey: configuration]
            let type = GROIncrementalStore.storeType
            
            try coordinator.addPersistentStoreWithType(type, configuration: nil, URL: nil, options: options)
            return coordinator
        }
        catch {
            return nil
        }
    }
}

extension NSManagedObjectContext {
    public static func mainContextForCoordinator(coordinator: NSPersistentStoreCoordinator) -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        return context
    }
    
    public func saveOrRollBack() -> Bool {
        do { try save(); return true }
        catch (let e) { print(e); rollback(); return false }
    }
}