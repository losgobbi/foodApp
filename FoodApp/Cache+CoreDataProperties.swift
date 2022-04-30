//
//  Cache+CoreDataProperties.swift
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

extension Cache {

    @NSManaged var created: NSTimeInterval
    @NSManaged var modified: NSTimeInterval
    @NSManaged var cacheLine: Line
    @NSManaged var cacheCategory: Category
    @NSManaged var cacheProduct: Product

}
