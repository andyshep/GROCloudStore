//
//  AsyncOperation.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/17/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import Foundation

public class AsyncOperation: Operation {
    
    private var _executing = false
    private var _finished = false
    
    public override func start() {
        if isCancelled {
            finish()
            return
        }
        
        willChangeValue(forKey: "isExecuting")
        _executing = true
        didChangeValue(forKey: "isExecuting")
        
        main()
    }
    
    public func finish() {
        willChangeValue(forKey: "isExecuting")
        willChangeValue(forKey: "isFinished")
        _executing = false
        _finished = true
        didChangeValue(forKey: "isExecuting")
        didChangeValue(forKey: "isFinished")
    }
    
    public override var isExecuting: Bool {
        return _executing
    }
    
    public override var isFinished: Bool {
        return _finished
    }
    
    public override func cancel() {
        super.cancel()
        finish()
    }
}
