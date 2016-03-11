//
//  AsyncOperation.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/17/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import Foundation

class AsyncOperation: NSOperation {
    
    private var _executing = false
    private var _finished = false
    
    override func start() {
        if cancelled {
            finish()
            return
        }
        
        willChangeValueForKey("isExecuting")
        _executing = true
        didChangeValueForKey("isExecuting")
        
        main()
    }
    
    func finish() {
        willChangeValueForKey("isExecuting")
        willChangeValueForKey("isFinished")
        _executing = false
        _finished = true
        didChangeValueForKey("isExecuting")
        didChangeValueForKey("isFinished")
    }
    
    override var executing: Bool {
        return _executing
    }
    
    override var finished: Bool {
        return _finished
    }
    
    override func cancel() {
        super.cancel()
        finish()
    }
}