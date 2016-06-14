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

class CoreDataManager {
    
    static let sharedManager = CoreDataManager()
    
    // MARK: - Core Data stack
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return managedObjectContext
    }()
    
    // MARK: - Public
  
    #if os(iOS)
    func fetchedResultsController(forEntityName name: String, sortedBy sortDescriptors: [SortDescriptor], predicate: Predicate! = nil) -> NSFetchedResultsController<NSManagedObject> {
        let managedObjectContext = self.managedObjectContext
        let fetchRequest = NSFetchRequest<NSManagedObject>()
        let entity = NSEntityDescription.entity(forEntityName: name, in: managedObjectContext!)
        
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
    func arrayControllerForEntityName(_ name: String, sortDescriptors: [SortDescriptor] = []) -> NSArrayController {
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
        let url = try! URL.applicationDocumentsDirectory().appendingPathComponent("Todos.sqlite")
        
        let options = [GROConfigurationKey: TodoCloudConfiguration()];
        
        do {
           try coordinator.addPersistentStore(ofType: storeType, configurationName: nil, at: url, options: options)
        }
        catch {
            fatalError("Error creating persistent store: \(error)")
        }
        
        return coordinator
    }()
    
    private lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main().urlForResource("Todos", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
}
