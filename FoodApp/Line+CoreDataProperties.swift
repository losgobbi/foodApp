//
//  Line+CoreDataProperties.swift
//  
//
//  Created by Rodrigo Celso Gobbi on 2/29/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Line {

    @NSManaged var code: Int32
    @NSManaged var desc: String
    @NSManaged var name: String
    @NSManaged var startDate: NSTimeInterval
    @NSManaged var status: Int32
    @NSManaged var stopDate: NSTimeInterval
    @NSManaged var vendor: NSObject
    @NSManaged var lineImage: NSSet
    @NSManaged var lineProductList: NSSet
    @NSManaged var lineCache: Cache

}
