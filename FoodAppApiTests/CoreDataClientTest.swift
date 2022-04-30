//
//  CoreDataClientTest.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 11/14/16.
//  Copyright © 2016 Hagen. All rights reserved.
//

import XCTest
import CoreData
@testable import FoodApp

class CoreDataClientTest: XCTestCase {
    
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
    
    func testClientOverAll() {
        let moc = setUpInMemoryManagedObjectContext()

        let valid = Client.add(moc)
        valid.login = "valid"
        
        let login = try? Client.get(moc, login: "valid")
        XCTAssertNotNil(login, "cant find valid client")
        XCTAssert(login!!.login == "valid", "invalid client login")

        try! Client.rem(moc, login: "valid")
        let loginValid = try? Client.get(moc, login: "valid")
        XCTAssertNil(loginValid, "login was not removed")
        
        let user1 = Client.add(moc)
        user1.login = "user 1"
        let user2 = Client.add(moc)
        user2.login = "user 1"
        let user3 = Client.add(moc)
        user3.login = "user 1"

        let cls = Client.getAll(moc)
        XCTAssert(cls.count == 3, "invalid number of clients")
        
        let logins = try! Client.countLogin(moc, login: "user 1")
        XCTAssert(logins == 3, "cant find duplicated elements")
        
        moc.reset()
    }
    
    func testClientBks() {
        let moc = setUpInMemoryManagedObjectContext()
        let login = "my login is foo"
        
        let pd1 = Product.add(moc)
        pd1.id = Int32(1)
        pd1.desc = "frango"

        let pd2 = Product.add(moc)
        pd2.id = Int32(2)
        pd2.desc = "batata doce"

        let foo = Client.add(moc)
        foo.login = "my login is foo"
        
        var pd1_bk = try? Client.isProductInBookMarks(moc, login: login, pd: pd1)
        var pd2_bk = try? Client.isProductInBookMarks(moc, login: login, pd: pd2)
        XCTAssert(pd1_bk! == false, "pd was at bookmarks")
        XCTAssert(pd2_bk! == false, "pd was at bookmarks")
        
        let pdsEmpty = try! Client.getBookMarks(moc, login: login)
        XCTAssert(pdsEmpty!.count == 0, "bookmarks are not empty")
        
        try! Client.addBookMarks(moc, login: login, pd: pd1)
        let pds = try! Client.getBookMarks(moc, login: login)
        XCTAssert(pds!.count == 1, "bookmark was not inserted")

        pd1_bk = try? Client.isProductInBookMarks(moc, login: login, pd: pd1)
        pd2_bk = try? Client.isProductInBookMarks(moc, login: login, pd: pd2)
        XCTAssert(pd1_bk! == true, "pd wasnt at bookmarks")
        XCTAssert(pd2_bk! == false, "pd was at bookmarks")
        
        try! Client.remBookMarks(moc, login: login, pd: pd1)
        let pdsRemoved = try! Client.getBookMarks(moc, login: login)
        XCTAssert(pdsRemoved!.count == 0, "bookmarks were not removed")

        moc.reset()
    }
    
    func testClientCar() {
        let moc = setUpInMemoryManagedObjectContext()
        let login = "my login is foo"

        let client = Client.add(moc)
        client.login = login
        
        let line1 = Line.add(moc)
        line1.id = Int32(11)
        line1.desc = "line frango"

        let line2 = Line.add(moc)
        line2.id = Int32(12)
        line2.desc = "line batata"

        let pd1 = Product.add(moc)
        pd1.id = Int32(1)
        pd1.desc = "frango"
        pd1.productLine = line1

        //TODO add this to internal line
        let pd2 = Product.add(moc)
        pd2.id = Int32(2)
        pd2.desc = "carne"

        try! Client.addAnyCar(moc, login: login, pd: pd1, num: 50)
        XCTAssert(pd1.productListCount == 50, "elements were not added")
        
        do {
            try Client.addAnyCar(moc, login: login, pd: pd1, num: 51)
        } catch _ as NSError {
            XCTAssert(true, "exception was raised")
        }
        
        try! Client.addCar(moc, login: login, pd: pd2)
        XCTAssert(pd2.productListCount == 1, "elements were not added")
        
        try! Client.addAnyCar(moc, login: login, pd: pd2, num: 99)
        do {
            try Client.addCar(moc, login: login, pd: pd2)
        } catch _ as NSError {
            XCTAssert(true, "exception was raised")
        }
        
        var cars = try! Client.getCar(moc, login: login)
        XCTAssert(cars!.count == 2, "cant find login car")
        
        let isInCar = try? Client.isProductInCar(moc, login: login, pd: pd1)
        XCTAssert(isInCar! == true, "pd was not found at clients car")
        
        let pdsInvalidLine = try? Client.getCar(moc, login: login, filterLine: line2)
        XCTAssert(pdsInvalidLine!!.count == 0, "found invalid line at clients car")

        let pdsLine = try? Client.getCar(moc, login: login, filterLine: line1)
        XCTAssert(pdsLine!!.count == 1, "cant find line at clients car")
        
        let linesPds = try? Client.getCarLines(moc, login: login)
        XCTAssertNotNil(linesPds, "cant find lines at clients car")
        XCTAssert(linesPds!.count == 1, "found more than one line")
        XCTAssert(linesPds![0].id == 11, "foud invalid line")

        try! Client.removeFromCar(moc, login: login, pd: pd1)
        cars = try! Client.getCar(moc, login: login)
        XCTAssert(cars!.count == 1, "cant find login car")

        try! Client.removeCar(moc, login: login)
        cars = try! Client.getCar(moc, login: login)
        XCTAssert(cars!.count == 0, "cant find login car")

        moc.reset()
    }
    
    func testClientTransfer() {
        let moc = setUpInMemoryManagedObjectContext()

        let pd1 = Product.add(moc)
        pd1.id = Int32(1)
        pd1.desc = "frango"

        let cl1 = Client.add(moc)
        cl1.login = "src"
        let cl2 = Client.add(moc)
        cl2.login = "dst"
        
        let order = try? Order.addOrder(moc, login: "src")
        order!.addInfo = "my custom order"
        try! Client.addBookMarks(moc, login: "src", pd: pd1)
        try! Client.addCar(moc, login: "src", pd: pd1)

        try! Client.transferBookmarks(moc, from: "src", to: "dst")
        try! Client.transferCar(moc, from: "src", to: "dst")
        try! Client.transferOrder(moc, from: "src", to: "dst")
        
        let bkEmpty = try! Client.getBookMarks(moc, login: "src")
        XCTAssert(bkEmpty!.count == 0, "bk was not transfered from src")
        
        let carEmpty = try! Client.getCar(moc, login: "src")
        XCTAssert(carEmpty!.count == 0, "car was not transfered from src")
        
        let bkAdded = try! Client.getBookMarks(moc, login: "dst")
        XCTAssert(bkAdded!.count == 1, "bk was not transfered to dst")

        let carAdded = try! Client.getCar(moc, login: "dst")
        XCTAssert(carAdded!.count == 0, "car was not transfered to dst")
        
        //TODO how to check if source order is empty? Its not an optional
        //XCTAssertNotNil(cl1.clientOrder, "order was not transfered from src")
        //XCTAssertNil(cl2.clientOrder, "order was not transfered to dst")

        moc.reset()
    }
    
    func testRemoveAllCars() {
        let moc = setUpInMemoryManagedObjectContext()
        
        let pd1 = Product.add(moc)
        pd1.id = Int32(1)
        pd1.desc = "frango"

        let cl1 = Client.add(moc)
        cl1.login = "cl1"
        try! Client.addCar(moc, login: "cl1", pd: pd1)

        let cl2 = Client.add(moc)
        cl2.login = "cl2"
        try! Client.addAnyCar(moc, login: "cl1", pd: pd1, num: 5)
        
        Client.removeAllCars(moc)
        XCTAssert(pd1.productListCount == 0, "product was not removed")

        let car1 = try? Client.getCar(moc, login: "cl1")
        let car2 = try? Client.getCar(moc, login: "cl2")
        XCTAssert(car1!!.count == 0, "car1 was not empty")
        XCTAssert(car2!!.count == 0, "car1 was not empty")
        
        moc.reset()
    }
    
    func testClientAddress() {
        let moc = setUpInMemoryManagedObjectContext()
        let login = "my login"
        
        let cl = Client.add(moc)
        cl.login = login

        let addr1 = Address.add(moc)
        addr1.id = 1
        addr1.address = "foo1"
        
        let addr2 = Address.add(moc)
        addr2.id = 2
        addr2.address = "foo2"

        let addr3 = Address.add(moc)
        addr3.id = 3
        addr3.address = "foo3"

        try! Client.addAddress(moc, login: login, address: addr1)
        try! Client.addAddress(moc, login: login, address: addr2)
        try! Client.addAddress(moc, login: login, address: addr3)
        
        let addresses = try! Client.getAddresses(moc, login: login)
        XCTAssert(addresses!.count == 3, "there are no three addresses")
        
        //TODO first is the first addr added? This could be random
        let firstAddr = try! Client.getFirstAddress(moc, login: login)
        XCTAssertNotNil(firstAddr, "cant find first address")
        XCTAssert(firstAddr!.id == 1, "invalid first address")

        try! Client.remAddress(moc, login: login, address: addr1)
        let secondAddr = try! Client.getFirstAddress(moc, login: login)
        XCTAssert(secondAddr!.id == 2, "invalid first address")
        
        try! Client.remAddress(moc, login: login, address: addr2)
        try! Client.remAddress(moc, login: login, address: addr3)
        let emptyAddresses = try! Client.getAddresses(moc, login: login)
        XCTAssert(emptyAddresses!.count == 0, "client addresses are not nil")

        moc.reset()
    }
    
    func testClientSyncTime() {
        let moc = setUpInMemoryManagedObjectContext()

        Client.addSyncTime(moc)
        
        let cl = try? Client.get(moc, login: defaultUser)
        XCTAssert(cl!!.login == defaultUser, "time is not attached to dftUser")
        moc.reset()
    }
}
