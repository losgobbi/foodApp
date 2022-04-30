//
//  CoreDataProductTest.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 11/15/16.
//  Copyright © 2016 Hagen. All rights reserved.
//

import XCTest
import CoreData
@testable import FoodApp

class CoreDataProductTest: XCTestCase {
    
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
    
    func testProductOverAll() {
        let moc = setUpInMemoryManagedObjectContext()

        let pd = Product.add(moc)
        pd.id = 15
        pd.name = "Frango"
        pd.desc = "Desc Frango"
        pd.status = 1

        let pd1 = Product.add(moc)
        pd1.id = 16
        pd1.name = "Frango 1"
        pd1.desc = "Desc Frango 1"
        pd1.status = 1

        let pd2 = Product.add(moc)
        pd2.id = 17
        pd2.name = "Frango 2"
        pd2.desc = "Desc Frango 2"
        pd2.status = 1

        let pdInvalid = try? Product.get(moc, pdCode: 1)
        XCTAssertNil(pdInvalid, "found invalid element")

        var pdValid = try? Product.get(moc, pdCode: 15)
        XCTAssertNotNil(pdValid, "cant find valid element")
        
        XCTAssert(pdValid!!.id == 15, "found wrong element")
        
        Product.rem(moc, pd: pd)
        pdValid = try? Product.get(moc, pdCode: 15)
        XCTAssertNil(pdValid, "element was not removed")
        
        let pds = try? Product.getAll(moc)
        XCTAssert(pds!!.count == 2, "not enough products")

        moc.reset()
    }
    
    func testProductRandom() {
        let moc = setUpInMemoryManagedObjectContext()
        
        let pd = Product.add(moc)
        pd.id = 15
        pd.name = "Frango"
        pd.desc = "Desc Frango"
        pd.status = 1
        
        let pd1 = Product.add(moc)
        pd1.id = 16
        pd1.name = "Frango 1"
        pd1.desc = "Desc Frango 1"
        pd1.status = 1

        let pd2 = Product.add(moc)
        pd2.id = 17
        pd2.name = "Frango 2"
        pd2.desc = "Desc Frango 2"
        pd2.status = 1

        var random2 = try? Product.getRandom(moc, count: 2)
        let count = random2!!.count
        XCTAssert(count == 2, "cant find two random products")
        
        let id1 = random2!![0].id
        let id2 = random2!![1].id
        XCTAssert(id1 != id2, "elements are not random")
        
        moc.reset()
    }
    
    func testProductPromo() {
        let moc = setUpInMemoryManagedObjectContext()
        
        let pd = Product.add(moc)
        pd.id = 15
        pd.name = "Frango"
        pd.desc = "Desc Frango"
        pd.status = 1
        
        let pd1 = Product.add(moc)
        pd1.id = 16
        pd1.name = "Frango 1"
        pd1.desc = "Desc Frango 1"
        pd1.status = 1
        pd1.discount = true

        let promos = try? Product.getPromo(moc)
        XCTAssert(promos!!.count == 1, "found wrong number of promo")
        XCTAssert(promos!![0].id == 16, "found wrong element")

        moc.reset()
    }
}
