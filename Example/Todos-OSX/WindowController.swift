//
//  WindowController.swift
//  Todos
//
//  Created by Andrew Shepard on 5/26/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {
    
    lazy var arrayController: NSArrayController = {
        let descriptors = [SortDescriptor(key: "created", ascending: true)]
        let controller = CoreDataManager.sharedManager.arrayControllerForEntityName("Todo", sortDescriptors: descriptors)
        
        let context = CoreDataManager.sharedManager.managedObjectContext
        controller.managedObjectContext = context
        
        return controller
    }()

    override func windowDidLoad() {
        super.windowDidLoad()
        
        self.window?.titleVisibility = .hidden
        
        if let viewController = self.contentViewController as? ViewController {
            viewController.representedObject = self.arrayController
        }
    }

    @IBAction func handleAddButton(_ sender: AnyObject) {
        print("add")
        
        guard let context = arrayController.managedObjectContext else { fatalError() }
        guard let todo = NSEntityDescription.insertNewObject(forEntityName: "Todo", into: context) as? Todo else { fatalError() }
        
        todo.item = "Automatic"
        todo.created = Date()
        
        self.arrayController.insert(todo)
        context.saveOrLogError()
    }
}
