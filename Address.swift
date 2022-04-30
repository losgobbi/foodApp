//
//  Address+Mgmt.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 6/28/15.
//  Copyright (c) 2015 Hagen. All rights reserved.
//
//  Extension for handling Address Management Object
//

import Foundation
import CoreData

class Address: NSManagedObject {
    
    class func add(moc: NSManagedObjectContext) -> Address {
        let addr = NSEntityDescription.insertNewObjectForEntityForName(
            "Address", inManagedObjectContext: moc) as! Address
        return addr
    }
    
    class func rem(moc: NSManagedObjectContext, address: String) throws {
        let fetchReq = NSFetchRequest(entityName: "Address")
        fetchReq.predicate = NSPredicate(format: "address = %@", address)
        var ad = try moc.executeFetchRequest(fetchReq) as! [Address]
        
        guard ad.count > 0 else {
            throw error(message: "Address.rem() not found address = \(address)",
                errorCode: Codes.ElementNotFound.rawValue)
        }
        
        for i in 0..<ad.count {
            moc.deleteObject(ad[i])
        }
    }
    
    class func remAll(moc: NSManagedObjectContext) throws {
        let fetchReq = NSFetchRequest(entityName: "Address")
        var ad = try moc.executeFetchRequest(fetchReq) as! [Address]
        
        for i in 0..<ad.count {
            moc.deleteObject(ad[i])
        }
    }
}
