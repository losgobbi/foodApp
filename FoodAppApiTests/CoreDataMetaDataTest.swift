//
//  CoreDataMetaDataTest.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 11/12/16.
//  Copyright © 2016 Hagen. All rights reserved.
//

import XCTest
import CoreData
@testable import FoodApp

class CoreDataMetaDataTest: XCTestCase {
    
    func setUpInMemoryManagedObjectContext() -> NSManagedObjectContext {
        let managedObjectModel = NSManagedObjectModel.mergedModelFromBundles([NSBundle.mainBundle()])!
        
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        
        do {
            try persistentStoreCoordinator.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil)
        } catch {
            print("Adding in-memory persistent store failed")
        }
        
        let managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        return managedObjectContext
    }

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testMeta() {
        let moc = setUpInMemoryManagedObjectContext()

        let info1 = MetaData.add(moc)
        info1.count = 10
        
        let findMeta1 = try? MetaData.get(moc)
        XCTAssertNotNil(findMeta1, "Cant find meta")

        let info2 = MetaData.add(moc)
        info2.count = 20
        
        let findMeta2 = try? MetaData.get(moc)
        XCTAssertNil(findMeta2, "number of meta not allowed")
        
        MetaData.rem(moc, metaInfo: info1)
        MetaData.rem(moc, metaInfo: info1)
        
        let findMetaAll = try? MetaData.get(moc)
        XCTAssertNotNil(findMetaAll, "meta was not deleted")
        
        moc.reset()
    }
}
