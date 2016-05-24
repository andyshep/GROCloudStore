//
//  Array+NSOperation.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 3/11/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

// http://blog.krzyzanowskim.com/2015/11/25/code-at-the-end-of-the-queue/

import Foundation

extension Array where Element: NSOperation {
    func onFinish(block: () -> Void) {
        let completion = NSBlockOperation(block: block)
        self.forEach { [unowned completion] in completion.addDependency($0) }
        NSOperationQueue().addOperation(completion)
    }
}