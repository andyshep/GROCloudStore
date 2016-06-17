//
//  AccountStatusOperation.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 6/16/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import Foundation

class AccountStatusOperation: AsyncOperation {

    private(set) var status: CKAccountStatus?
    private let dataSource: CloudDataSource
    
    init(dataSource: CloudDataSource) {
        self.dataSource = dataSource
        super.init()
    }
    
    override func main() {
        let group = DispatchGroup()
        group.enter()
        
        let container = self.dataSource.container
        container.accountStatus { (status, error) in
            guard error == nil else {
                fatalError()
            }
            
            self.status = status
            group.leave()
        }
        
        let queue = DispatchQueue.global()
        group.notify(queue: queue) { [unowned self] in
            self.finish()
        }
    }
}
