//
//  Order+CoreDataProperties.swift
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

extension Order {

    @NSManaged var addInfo: String?
    @NSManaged var date: String?
    @NSManaged var discountInfo: String?
    @NSManaged var pay: String?
    @NSManaged var time: String?
    @NSManaged var orderClient: Client?

}
