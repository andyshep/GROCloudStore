//
//  ViewController.swift
//  Todos
//
//  Created by Andrew Shepard on 5/23/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    lazy var fetchedResultsController: NSFetchedResultsController<NSManagedObject> = {
        let descriptors = [NSSortDescriptor(key: "created", ascending: true)]
        let controller = CoreDataManager.sharedManager.fetchedResultsController(forEntityName: "Todo", sortedBy: descriptors)
        
        controller.delegate = self
        
        return controller
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Todos"
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.tableView.dataSource = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AddTodoItem" {
            guard let navController = segue.destination as? UINavigationController else { return }
            guard let addViewController = navController.viewControllers.first as? AddViewController else { return }
            
            addViewController.context = self.fetchedResultsController.managedObjectContext
        }
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath as IndexPath)
        guard let todo = fetchedResultsController.fetchedObjects?[indexPath.row] as? Todo else { fatalError() }
        
        cell.textLabel?.text = todo.item
        
        return cell
    }
}

extension ViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView?.reloadData()
    }
}
