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

func createInMemoryContext(using model: NSManagedObjectModel, completion: @escaping (NSManagedObjectContext?, Error?) -> Void) {
    let container = NSPersistentContainer(name: "GROCloudStore", managedObjectModel: model)
    
    let description = NSPersistentStoreDescription(url: testDatabaseURL())
    description.type = GROIncrementalStore.storeType
    
    description.setOption(NSNumber(value: true), forKey: NSMigratePersistentStoresAutomaticallyOption)
    description.setOption(NSNumber(value: true), forKey: NSInferMappingModelAutomaticallyOption)
    
    let dataSource = GROTestDataSource()
    let configuration = GROTestConfiguration()
    
    description.setOption(dataSource, forKey: GRODataSourceKey)
    description.setOption(configuration, forKey: GROConfigurationKey)
    description.setOption(NSNumber(value: true), forKey: GROUseInMemoryStoreKey)
    
    container.persistentStoreDescriptions = [description]
    
    container.loadPersistentStores { [unowned container] (description, error) in
        let context = container.viewContext
        completion(context, error)
    }
}

func testDatabaseURL() -> URL {
    let path = NSTemporaryDirectory().appending("sample.sqlite")
    let url = URL(fileURLWithPath: path)
    return url
}

public func saveContext(_ context: NSManagedObjectContext) {
    if context.hasChanges {
        do {
            try context.save()
        }
        catch (let error as NSError) {
            fatalError("error saving context: \(error)")
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
