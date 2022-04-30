//
//  Order+Mgmt.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 10/26/15.
//  Copyright © 2015 Hagen. All rights reserved.
//
//  Extension for handling Order Management Object
//

import Foundation
import CoreData

class Order: NSManagedObject {
    
    class func addOrder(moc: NSManagedObjectContext, login: String) throws -> Order {
        let order = NSEntityDescription.insertNewObjectForEntityForName(
            "Order", inManagedObjectContext: moc) as! Order
        let cl = try Client.get(moc, login: login)
        
        /* attach order to client */
        cl!.clientOrder = order
        return order
    }
    
    class func remOrder(moc: NSManagedObjectContext, login: String) throws {
        let cl = try Client.get(moc, login: login)
        moc.deleteObject(cl!.clientOrder)
    }
}
