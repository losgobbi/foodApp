//
//  CoreDataDeliveryFormTest.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 11/12/16.
//  Copyright © 2016 Hagen. All rights reserved.
//

import XCTest
import CoreData
@testable import FoodApp

class CoreDataDeliveryFormTest: XCTestCase {
    
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
    
    func testDeliveryForm() {
        let moc = setUpInMemoryManagedObjectContext()
        
        let df1 = DeliveryForm.add(moc)
        df1.id = Int32(1)
        df1.name = "Forma 1"

        let df2 = DeliveryForm.add(moc)
        df2.id = Int32(2)
        df2.name = "Forma 2"

        let dfInvalid = try? DeliveryForm.get(moc, formId: 3)
        XCTAssertNil(dfInvalid, "find invalid df")
        
        let dfValid1 = try? DeliveryForm.get(moc, formId: 1)
        XCTAssertNotNil(dfValid1, "find invalid df")
        XCTAssert(dfValid1!!.name == "Forma 1", "invalid df name")

        let dfAll = try? DeliveryForm.getAll(moc)
        XCTAssert(dfAll!!.count == 2, "invalid df number")
        
        moc.reset()
    }
}
