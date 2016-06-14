//
//  AddViewController.swift
//  Todos
//
//  Created by Andrew Shepard on 5/24/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import UIKit
import CoreData

class AddViewController: UIViewController {
    
    @IBOutlet weak var textField: UITextField!
    
    var context: NSManagedObjectContext?
    
    @IBAction func handleDoneButton(sender: AnyObject) {
        defer { dismiss(animated: true, completion: nil) }
        
        guard let context = context else { return }
        
        let item = self.textField.text ?? ""
        if item.characters.count > 0 {
            
            guard let todo = NSEntityDescription.insertNewObject(forEntityName: "Todo", into: context) as? Todo else { return }
            
            todo.item = item
            todo.created = Date()
            
            context.saveOrLogError()
        }
    }
}
