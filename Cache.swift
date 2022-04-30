//
//  Cache+Mgmt.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 2/29/16.
//  Copyright © 2016 Hagen. All rights reserved.
//
//  Extension for handling Cache Management Object
//

import Foundation
import CoreData

class Cache: NSManagedObject {
    
    class func add(moc: NSManagedObjectContext) -> Cache {
        let cache = NSEntityDescription.insertNewObjectForEntityForName(
            "Cache", inManagedObjectContext: moc) as! Cache
        return cache
    }
}
