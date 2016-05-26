//
//  CoreDataManager.swift
//  Todos
//
//  Created by Andrew Shepard on 12/10/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import CoreData
import GROCloudStore

#if os(OSX)
import AppKit
#endif

class CoreDataManager: NSObject {
    
    // MARK: - Lifecycle
    
    static let sharedManager = CoreDataManager()
    
    override init() {
        super.init()
    }
    
    // MARK: - Core Data stack
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return managedObjectContext
    }()
    
    // MARK: - Public
  
    #if os(iOS)
    func fetchedResultsControllerForEntityName(name: String, sortDescriptors: [NSSortDescriptor], predicate:NSPredicate! = nil) -> NSFetchedResultsController {
        let managedObjectContext = self.managedObjectContext
        let fetchRequest = NSFetchRequest()
        let entity = NSEntityDescription.entityForName(name, inManagedObjectContext: managedObjectContext!)
        
        fetchRequest.entity = entity
        fetchRequest.fetchBatchSize = 20
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.predicate = predicate
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fetchedResultsController.performFetch()
        }
        catch {
            fatalError("Error creating frc: \(error)")
        }
        
        return fetchedResultsController;
    }
    
    #elseif os(OSX)
    func arrayControllerForEntityName(name: String, sortDescriptors: [NSSortDescriptor] = []) -> NSArrayController {
        let controller = NSArrayController()
        
        controller.entityName = name
        controller.sortDescriptors = sortDescriptors
        controller.automaticallyPreparesContent = false
        
        return controller
    }
    
    #endif
    
    // MARK: - Private
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        let storeType = GROIncrementalStore.storeType
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = NSURL.applicationDocumentsDirectory().URLByAppendingPathComponent("Todos.sqlite")
        
        let options = [GROConfigurationKey: TodoCloudConfiguration()];
        
        do {
           try coordinator.addPersistentStoreWithType(storeType, configuration: nil, URL: url, options: options)
        }
        catch {
            fatalError("Error creating persistent store: \(error)")
        }
        
        return coordinator
    }()
    
    private lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = NSBundle.mainBundle().URLForResource("Todos", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
}
