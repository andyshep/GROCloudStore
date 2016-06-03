//
//  CoreData+Extensions.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 11/13/15.
//  Copyright © 2015 Andrew Shepard. All rights reserved.
//

import Foundation
import CoreData
@testable import GROCloudStore

public func createInMemoryContext(model: NSManagedObjectModel) -> NSManagedObjectContext? {
    
    if let coordinator = NSPersistentStoreCoordinator.coordinatorWithInMemoryStore(using: model) {
        let context = NSManagedObjectContext.mainContext(for: coordinator)
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
    public static func coordinatorWithInMemoryStore(using model: NSManagedObjectModel) -> NSPersistentStoreCoordinator? {
        do {
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
            let dataSource = GROTestDataSource()
            let configuration = GROTestConfiguration()
            
            let options: [NSObject: AnyObject] = [GRODataSourceKey: dataSource, GROUseInMemoryStoreKey: NSNumber(value: true), GROConfigurationKey: configuration]
            let type = GROIncrementalStore.storeType
            
            try coordinator.addPersistentStore(ofType: type, configurationName: nil, at: nil, options: options)
            return coordinator
        }
        catch {
            return nil
        }
    }
}

extension NSManagedObjectContext {
    public static func mainContext(for coordinator: NSPersistentStoreCoordinator) -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        return context
    }
    
    public func saveOrRollBack() -> Bool {
        do { try save(); return true }
        catch (let e) { print(e); rollback(); return false }
    }
}