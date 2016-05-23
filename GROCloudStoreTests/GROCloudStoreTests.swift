//
//  GROCloudStoreTests.swift
//  GROCloudStoreTests
//
//  Created by Andrew Shepard on 3/11/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import XCTest
@testable import GROCloudStore

class GROCloudStoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    var model: NSManagedObjectModel {
        let contentAttribute = NSAttributeDescription()
        contentAttribute.name = "content"
        contentAttribute.attributeType = NSAttributeType.StringAttributeType
        contentAttribute.optional = false
        contentAttribute.indexed = true
        
        let testEntity = NSEntityDescription()
        testEntity.name = "GROTestEntity"
        testEntity.properties = [contentAttribute]
        
        let model = NSManagedObjectModel()
        model.entities = [testEntity]
        
        return model
    }
    
    func test_canCreateContext() {
        
        let model = self.model
        let context = createInMemoryContext(model)
        
        XCTAssert(context != nil, "context should not be nil")
    }
}
