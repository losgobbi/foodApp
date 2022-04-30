//
//  Line+CoreDataProperties.swift
//  
//
//  Created by Rodrigo Celso Gobbi on 3/8/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Line {

    @NSManaged var desc: String
    @NSManaged var id: Int32
    @NSManaged var name: String
    @NSManaged var startDate: NSTimeInterval
    @NSManaged var status: Int16
    @NSManaged var stopDate: NSTimeInterval
    @NSManaged var vendor: NSObject
    @NSManaged var syncedProducts: Bool
    @NSManaged var lineCache: Cache
    @NSManaged var lineImage: NSSet
    @NSManaged var lineProductList: NSSet

}
