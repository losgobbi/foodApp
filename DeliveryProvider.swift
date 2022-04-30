//
//  DeliveryProvider+Mgmt.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 6/28/15.
//  Copyright (c) 2015 Hagen. All rights reserved.
//
//  Extension for handling DeliveryProvider Management Object
//

import Foundation
import CoreData

class DeliveryProvider: NSManagedObject {
    
    class func add(moc: NSManagedObjectContext) -> DeliveryProvider {
        let dp = NSEntityDescription.insertNewObjectForEntityForName(
            "DeliveryProvider", inManagedObjectContext: moc) as! DeliveryProvider
        return dp
    }
    
    class func get(moc: NSManagedObjectContext) throws -> DeliveryProvider? {
        let fetchReq = NSFetchRequest(entityName: "DeliveryProvider")
        let dp = try moc.executeFetchRequest(fetchReq) as! [DeliveryProvider]
        
        guard dp.count > 0 else {
            throw error(message: "DeliveryProvider.get() not found",
                errorCode: Codes.ElementNotFound.rawValue)
        }
        
        return dp[0]
    }
}
