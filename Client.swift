//
//  Client.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 6/20/15.
//  Copyright (c) 2015 Hagen. All rights reserved.
//
//  Extension for handling Client Management Object
//

import Foundation
import CoreData

class Client: NSManagedObject {
    
    class func add(moc: NSManagedObjectContext) -> Client {
        let client = NSEntityDescription.insertNewObjectForEntityForName(
            "Client", inManagedObjectContext: moc) as! Client
        return client
    }
    
    class func rem(moc: NSManagedObjectContext, login: String) throws {
        let fetchReq = NSFetchRequest(entityName: "Client")
        fetchReq.predicate = NSPredicate(format: "login = %@", login)
        var cl = try moc.executeFetchRequest(fetchReq) as! [Client]
        
        guard cl.count > 0 else {
            throw error(message: "Client.get() not found login = \(login)",
                errorCode: Codes.ElementNotFound.rawValue)
        }
        
        for i in 0..<cl.count {
            moc.deleteObject(cl[i])
        }
    }
    
    class func addSyncTime(moc: NSManagedObjectContext) {
        let cl = NSEntityDescription.insertNewObjectForEntityForName(
            "Client", inManagedObjectContext: moc) as! Client
        let localTime = NSDate()
        cl.syncTime = localTime.timeIntervalSinceReferenceDate
        
        /* sync time is not attached to a valid user */
        cl.login = defaultUser
    }
    
    class func addAddress(moc: NSManagedObjectContext,
        login: String, address: Address) throws {
            let cl = try get(moc, login: login)
            let addr = cl!.mutableSetValueForKeyPath("clientAddress")
            
            addr.addObject(address)
    }
    
    class func remAddress(moc: NSManagedObjectContext,
        login: String, address: Address) throws {
            let cl = try get(moc, login: login)
            let addr = cl!.mutableSetValueForKeyPath("clientAddress")
            
            addr.removeObject(address)
    }

    class func getAddresses(moc: NSManagedObjectContext, login: String) throws -> [Address]? {
        let cl = try get(moc, login: login)
        let ad = cl!.mutableSetValueForKeyPath("clientAddress").allObjects as! [Address]
        return ad
    }
    
    class func getFirstAddress(moc: NSManagedObjectContext, login: String) throws -> Address? {
        return try self.getAddresses(moc, login: login)!.first
    }
    
    class func get(moc: NSManagedObjectContext, login: String) throws -> Client? {
        let fetchReq = NSFetchRequest(entityName: "Client")
        fetchReq.predicate = NSPredicate(format: "login = %@", login)
        let cl = try moc.executeFetchRequest(fetchReq) as! [Client]
        
        guard cl.count > 0 else {
            throw error(message: "Client.get() not found login = \(login)",
                errorCode: Codes.ElementNotFound.rawValue)
        }
        
        return cl[0]
    }
    
    class func getAll(moc: NSManagedObjectContext) -> [Client] {
        let fetchReq = NSFetchRequest(entityName: "Client")
        let cl = try! moc.executeFetchRequest(fetchReq) as! [Client]

        return cl
    }
    
    class func countLogin(moc: NSManagedObjectContext, login: String) throws -> Int {
        let fetchReq = NSFetchRequest(entityName: "Client")
        fetchReq.predicate = NSPredicate(format: "login = %@", login)
        let cl = try moc.executeFetchRequest(fetchReq) as! [Client]

        guard cl.count > 0 else {
            return 0
        }
        
        return cl.count
    }
    
    class func addBookMarks(moc: NSManagedObjectContext,
        login: String, pd: Product) throws {
            let cl = try get(moc, login: login)
            let bk = cl!.mutableSetValueForKeyPath("clientBookMarks")
            
            bk.addObject(pd)
    }
    
    class func remBookMarks(moc: NSManagedObjectContext,
        login: String, pd: Product) throws {
            let cl = try get(moc, login: login)
            let bk = cl!.mutableSetValueForKeyPath("clientBookMarks")
            
            bk.removeObject(pd)
    }
    
    class func getBookMarks(moc: NSManagedObjectContext,
        login: String) throws -> [Product]? {
            let cl = try get(moc, login: login)
            let bk = cl!.mutableSetValueForKeyPath("clientBookMarks").allObjects as! [Product]
            return bk
    }
    
    class func isProductInBookMarks(moc: NSManagedObjectContext,
        login: String, pd: Product) throws -> Bool {
            let cl = try get(moc, login: login)
            let bk = cl!.mutableSetValueForKeyPath("clientBookMarks")
            
            return bk.containsObject(pd)
    }
    
    /* This func transfers the bookmarks, it do not copy them */
    class func transferBookmarks(moc: NSManagedObjectContext, from: String, to: String) throws {
        let clfrom = try get(moc, login: from)
        let clto = try get(moc, login: to)

        var bkfrom = clfrom!.mutableSetValueForKeyPath("clientBookMarks").allObjects
        let bkto = clto!.mutableSetValueForKeyPath("clientBookMarks")

        bkto.addObjectsFromArray(bkfrom)
        bkfrom.removeAll()

    }

    /* This func transfers the cart itens, it do not copy them */
    class func transferCar(moc: NSManagedObjectContext, from: String, to: String) throws {
        let clfrom = try get(moc, login: from)
        let clto = try get(moc, login: to)
        
        var cartfrom = clfrom!.mutableSetValueForKeyPath("clientProductList").allObjects
        let cartto = clto!.mutableSetValueForKeyPath("clientProductList")
        
        cartto.addObjectsFromArray(cartfrom)
        cartfrom.removeAll()
    }
    
    /* weird, this seems to transfer the order, not copy. For now, this is ok...*/
    class func transferOrder(moc: NSManagedObjectContext, from: String, to: String) throws {
        let clfrom = try get(moc, login: from)
        let clto = try get(moc, login: to)
        
        clto!.clientOrder = clfrom!.clientOrder
    }
    
    class func addAnyCar(moc: NSManagedObjectContext,
        login: String, pd: Product, num: Int) throws {
        let cl = try get(moc, login: login)
        let car = cl!.mutableSetValueForKeyPath("clientProductList")
        
        guard (Int(pd.productListCount) + num <= maxProductAmount) else {
            throw error(message: "Client.addCar() Amount reached the limit pd = \(pd.name)",
                errorCode: Codes.MaxProductAmountReached.rawValue)
        }
        
        if (car.containsObject(pd)) {
            /* increase the amount */
            pd.productListCount += Int16(num)
        } else {
            /* first object */
            car.addObject(pd)
            pd.productListCount = Int16(num)
        }
    }
    
    
    class func addCar(moc: NSManagedObjectContext,
        login: String, pd: Product) throws {
            let cl = try get(moc, login: login)
            let car = cl!.mutableSetValueForKeyPath("clientProductList")
            
            if (car.containsObject(pd)) {
                
                let increase = Int(pd.productListCount) + 1
                guard (increase <= maxProductAmount) else {
                    throw error(message: "Client.addCar() Amount reached the limit pd = \(pd.name)",
                        errorCode: Codes.MaxProductAmountReached.rawValue)
                }
                
                /* increase the amount */
                pd.productListCount += 1
            } else {
                /* first object */
                car.addObject(pd)
                pd.productListCount = 1
            }
    }
    
    class func getCar(moc: NSManagedObjectContext, login: String) throws -> [Product]? {
        let cl = try get(moc, login: login)
        let car = cl!.mutableSetValueForKeyPath("clientProductList").allObjects as! [Product]
        
        return car
    }
    
    class func isProductInCar(moc: NSManagedObjectContext,
        login: String, pd: Product) throws -> Bool {
            let cl = try get(moc, login: login)
            let car = cl!.mutableSetValueForKeyPath("clientProductList")
            
            return car.containsObject(pd)
    }
    
    /* get products from car in the filter line */
    class func getCar(moc: NSManagedObjectContext, login:
        String, filterLine: Line) throws -> [Product]? {
            let cl = try get(moc, login: login)
            var car = cl!.mutableSetValueForKeyPath("clientProductList").allObjects as! [Product]
            
            var carFiltered = NSSet()
            for i in 0..<car.count {
                /* set if its not the same line */
                if car[i].productLine.id == filterLine.id {
                    carFiltered = carFiltered.setByAddingObject(car[i])
                }
            }
            
            let pds = carFiltered.allObjects as! [Product]
            return pds
    }
    
    class func getCarLines(moc: NSManagedObjectContext,
        login: String) throws -> [Line] {
            let cl = try get(moc, login: login)
            let car = cl!.mutableSetValueForKeyPath("clientProductList").allObjects as! [Product]
            
            /* do not duplicate lines */
            var lines = NSSet()
            for i in 0..<car.count {
                let line = car[i].productLine
                lines = lines.setByAddingObject(line)
            }
            
            return lines.allObjects as! [Line]
    }
    
    class func removeFromCar(moc: NSManagedObjectContext,
        login: String, pd: Product) throws {
            let cl = try get(moc, login: login)
            let car = cl!.mutableSetValueForKeyPath("clientProductList")
            
            /* Reset amount */
            pd.productListCount = 0
            
            car.removeObject(pd)
    }
    
    class func removeCar(moc: NSManagedObjectContext, login: String) throws {
        let cl = try get(moc, login: login)
        let car = cl!.mutableSetValueForKeyPath("clientProductList")
        
        /* Reset amount */
        for i in 0..<car.count {
            let pd = car.allObjects[i] as! Product
            pd.productListCount = 0
        }
        
        car.removeAllObjects()
    }
    
    class func removeAllCars(moc: NSManagedObjectContext) {
        let cl = getAll(moc)
        
        for i in 0..<cl.count {
            /* it has been transferred or no user was logged */
            if cl[i].login == defaultUser {
                continue
            }
            let car = cl[i].mutableSetValueForKeyPath("clientProductList")
            /* Reset amount */
            for i in 0..<car.count {
                let pd = car.allObjects[i] as! Product
                pd.productListCount = 0
            }
            
            car.removeAllObjects()

        }
    }
}
