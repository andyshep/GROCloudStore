//
//  ViewController.swift
//  Todos-OSX
//
//  Created by Andrew Shepard on 5/23/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var tableView: NSTableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.window?.titleVisibility = .hidden
    }

    override var representedObject: Any? {
        didSet {
            guard let controller = representedObject as? NSArrayController else { return }
            
            self.tableView.bind(NSBindingName.content, to: controller, withKeyPath: "arrangedObjects", options: nil)
            self.tableView.bind(NSBindingName.selectionIndexes, to: controller, withKeyPath: "selectionIndexes", options: nil)
            
            controller.fetch(nil)
        }
    }
}

