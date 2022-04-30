//
//  CoreDataOrderTest.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 11/12/16.
//  Copyright © 2016 Hagen. All rights reserved.
//

import XCTest
import CoreData
@testable import FoodApp

class CoreDataOrderTest: XCTestCase {
    
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
    
    func testOrder() {
        let moc = setUpInMemoryManagedObjectContext()
        
        let orderInvalid = try? Order.addOrder(moc, login: "myuser")
        XCTAssertNil(orderInvalid, "found myuser client")
        
        let cl = Client.add(moc)
        cl.login = "myuser"
        
        let order = try? Order.addOrder(moc, login: "myuser")
        XCTAssertNotNil(order, "cant find myuser client")
        order!.id = Int32(1)
        order!.pay = "pay form"
        
        try! Order.remOrder(moc, login: "myuser")
        
        //TODO implement get method searching for orderid
        
        moc.reset()
    }
}
