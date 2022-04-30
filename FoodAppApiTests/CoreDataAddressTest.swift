//
//  CoreDataAddressTest.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 11/12/16.
//  Copyright © 2016 Hagen. All rights reserved.
//

import XCTest
import CoreData
@testable import FoodApp

class CoreDataAddressTest: XCTestCase {
    
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
    
    func testAddress() {
        let moc = setUpInMemoryManagedObjectContext()

        let addr1 = Address.add(moc)
        addr1.id = 7
        addr1.address = "foo1"
        
        let addr2 = Address.add(moc)
        addr2.id = 8
        addr2.address = "foo2"
        
        //TODO implement get method, to check if elements were removed
        
        try! Address.remAll(moc)

        moc.reset()
    }
}
