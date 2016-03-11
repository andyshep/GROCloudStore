//
//  AsyncOperation.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/17/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import Foundation

public class AsyncOperation: NSOperation {
    
    private var _executing = false
    private var _finished = false
    
    public override func start() {
        if cancelled {
            finish()
            return
        }
        
        willChangeValueForKey("isExecuting")
        _executing = true
        didChangeValueForKey("isExecuting")
        
        main()
    }
    
    public func finish() {
        willChangeValueForKey("isExecuting")
        willChangeValueForKey("isFinished")
        _executing = false
        _finished = true
        didChangeValueForKey("isExecuting")
        didChangeValueForKey("isFinished")
    }
    
    public override var executing: Bool {
        return _executing
    }
    
    public override var finished: Bool {
        return _finished
    }
    
    public override func cancel() {
        super.cancel()
        finish()
    }
}