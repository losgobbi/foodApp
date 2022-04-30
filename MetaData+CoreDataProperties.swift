//
//  MetaData+CoreDataProperties.swift
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

extension MetaData {

    @NSManaged var count: Int32
    @NSManaged var current: Int32
    @NSManaged var limit: Int32
    @NSManaged var nextPage: Bool
    @NSManaged var order: String?
    @NSManaged var page: Int32
    @NSManaged var pageCount: Int32

}
