//
//  CoreDataLineTest.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 11/3/16.
//  Copyright © 2016 Hagen. All rights reserved.
//

import XCTest
import CoreData
@testable import FoodApp

class CoreDataLineTest: XCTestCase {
    
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
    
    func testLineAdd() {
        let moc = setUpInMemoryManagedObjectContext()
        let lineId = Int32(1)
        let lineStatus = Int16(1)
        
        let lineObj = Line.add(moc)
        lineObj.id = lineId
        lineObj.name = "Test Line"
        lineObj.desc = "Test Line desc"
        lineObj.status = lineStatus
        
        let lineGet = try? Line.get(moc, lineCode: lineId)
        XCTAssertNotNil(lineGet, "Cant find line after inserting one")
        
        moc.reset()
    }
    
    func testLineRemove() {
        let moc = setUpInMemoryManagedObjectContext()
        let lineId = Int32(1)
        
        var lineRem = try? Line.get(moc, lineCode: lineId)
        XCTAssertNil(lineRem, "Found element")
        
        let lineObj = Line.add(moc)
        lineObj.id = lineId
        
        Line.rem(moc, line: lineObj)
        lineRem = try? Line.get(moc, lineCode: lineId)
        XCTAssertNil(lineRem, "Found line after remove it")
        
        moc.reset()
    }
    
    func testLineAddImage() {
        let moc = setUpInMemoryManagedObjectContext()
        let lineId = Int32(1)
        let imageId = Int32(2)
        
        let img1 = try? Image.getImageByPath(moc, path: "my path2")
        let img2 = try? Image.getImageByStringId(moc, id: "string id2")
        
        XCTAssertNil(img1, "found image by path")
        XCTAssertNil(img2, "found image by string id")
        
        let lineObj = Line.add(moc)
        lineObj.id = lineId
        
        let lineImage = Image.createImage(moc)
        lineImage.id = imageId
        lineImage.path = "my path"
        lineImage.stringIdentifier = "string id"
        lineImage.local = false
        lineImage.sizeBytes = 264
        
        Line.addImage(moc, line: lineObj, pd: lineImage)
        
        let img3 = try? Image.getImageByPath(moc, path: "my path")
        let img4 = try? Image.getImageByStringId(moc, id: "string id")
        XCTAssertNotNil(img3, "cant found image by path")
        XCTAssertNotNil(img4, "cant found image by string id")
        
        let count = try? Image.getDownloadedImages(moc)
        XCTAssert(count!!.count == 1, "cant find downloaded images")
        
        moc.reset()
    }
    
    func testLineAddPd() {
        let moc = setUpInMemoryManagedObjectContext()
        let pdId = Int32(1)
        let lineId = Int32(1)
        
        let lineObj = Line.add(moc)
        lineObj.id = lineId
        lineObj.status = 1
        
        let pdObj = Product.add(moc)
        pdObj.id = pdId
        pdObj.status = 1

        var pds = try? Line.getProductList(moc, line: lineObj)
        var count = pds!!.count
        XCTAssert(count == 0, "pds list is not empty")
        
        Line.addProduct(moc, line: lineObj, pd: pdObj)
        
        pds = try? Line.getProductList(moc, line: lineObj)
        count = pds!!.count
        XCTAssert(count != 0, "pds list is empty")
        
        moc.reset()
    }
    
    func testLineGetProductList() {
        let moc = setUpInMemoryManagedObjectContext()
        let pdId1 = Int32(1)
        let pdId2 = Int32(2)
        let lineId = Int32(1)
        
        let lineObj = Line.add(moc)
        lineObj.id = lineId
        lineObj.status = 1
        
        let pdObj1 = Product.add(moc)
        pdObj1.id = pdId1
        pdObj1.status = 1

        let pdObj2 = Product.add(moc)
        pdObj2.id = pdId2
        pdObj2.status = 1

        Line.addProduct(moc, line: lineObj, pd: pdObj1)
        Line.addProduct(moc, line: lineObj, pd: pdObj2)

        let pds = try? Line.getProductList(moc, line: lineObj)
        let count = pds!!.count
        XCTAssert(count == 2, "there are not enough elements")

        let lineInvalid = Line.add(moc)
        lineInvalid.id = lineId + 1
        let pdsInvalid = try? Line.getProductList(moc, line: lineInvalid)
        let countInvalid = pdsInvalid?!.count
        print("countInvalid = \(countInvalid)")
        XCTAssertNil(countInvalid, "pds list for invalid line is not empty")
        
        moc.reset()
    }
    
    func testLineRemovePd() {
        let moc = setUpInMemoryManagedObjectContext()
        let pdId = Int32(1)
        let lineId = Int32(1)

        let lineObj = Line.add(moc)
        lineObj.id = lineId
        lineObj.status = 1
        
        let pdObj = Product.add(moc)
        pdObj.id = pdId
        
        Line.addProduct(moc, line: lineObj, pd: pdObj)
        Line.removeProduct(moc, line: lineObj, pd: pdObj)
        
        let pds = try? Line.getProductList(moc, line: lineObj)
        let count = pds!!.count
        XCTAssert(count == 0, "pds list is not empty")
        
        moc.reset()
    }
    
    func testLineGetRandom() {
        let moc = setUpInMemoryManagedObjectContext()
        
        let line1 = Line.add(moc)
        line1.id = 1
        line1.status = 1

        let line2 = Line.add(moc)
        line2.id = 2
        line2.status = 1

        let line3 = Line.add(moc)
        line3.id = 3
        line3.status = 1

        let line4 = Line.add(moc)
        line4.id = 4
        line4.status = 1

        let random2 = try? Line.getRandom(moc, count: 2)
        let count = random2!!.count
        XCTAssert(count == 2, "cant find two random lines")
        
        let id1 = random2!![0].id
        let id2 = random2!![1].id
        XCTAssert(id1 != id2, "elements are not random")
        
        moc.reset()
    }
    
    func testLineGetAll() {
        let moc = setUpInMemoryManagedObjectContext()

        let line1 = Line.add(moc)
        line1.id = 1
        line1.status = 1

        let line2 = Line.add(moc)
        line2.id = 2
        line2.status = 1
        
        let line3 = Line.add(moc)
        line3.id = 3
        line3.status = 1

        let line4 = Line.add(moc)
        line4.id = 3

        let lines = try? Line.getAll(moc)
        print("lines!!.count = \(lines!!.count)")
        XCTAssert(lines!!.count == 3, "line list has not enough elements")

        moc.reset()
    }
    
    func testLineGetOutOfSync() {
        let moc = setUpInMemoryManagedObjectContext()

        let line1 = Line.add(moc)
        line1.id = 1
        line1.syncedProducts = true
        
        let of = try? Line.getOutOfSync(moc)
        XCTAssertNil(of, "Find out-of-sync element")
        
        line1.syncedProducts = false
        let of1 = try? Line.getOutOfSync(moc)
        XCTAssertNotNil(of1, "Cant find out-of-sync element")
        
        moc.reset()
    }
}
