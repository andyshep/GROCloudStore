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
    
    let testModel = createTestModel()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        NSPersistentStoreCoordinator.registerStoreClass(GROIncrementalStore.self, forStoreType: GROIncrementalStore.storeType)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test_canCreateContext() {
        let expected = expectation(description: "context should be created")
        let timeout = 10.0
        
        createInMemoryContext(using: testModel) { context, error in
            XCTAssert(context != nil, "context should not be nil")
            
            expected.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
    }
}

func createTestModel() -> NSManagedObjectModel {
    let contentAttribute = NSAttributeDescription()
    contentAttribute.name = "content"
    contentAttribute.attributeType = NSAttributeType.stringAttributeType
    contentAttribute.isOptional = false
    contentAttribute.isIndexed = true
    
    let testEntity = NSEntityDescription()
    testEntity.name = "TestEntity"
    testEntity.properties = [contentAttribute]
    
    let model = NSManagedObjectModel()
    model.entities = [testEntity]
    
    return model
}
