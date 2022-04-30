//
//  Characteristic+CoreDataProperties.swift
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

extension Characteristic {

    @NSManaged var code: Int32
    @NSManaged var name: String
    @NSManaged var characteristicProduct: NSSet

}
