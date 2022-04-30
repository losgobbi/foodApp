//
//  DeliveryProvider+CoreDataProperties.swift
//  
//
//  Created by Rodrigo Celso Gobbi on 3/4/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension DeliveryProvider {

    @NSManaged var name: String
    @NSManaged var phone: String
    @NSManaged var vendor: NSObject
    @NSManaged var id: Int32
    @NSManaged var deliveryAddress: Address
    @NSManaged var deliveryImage: Image
    @NSManaged var deliveryForm: NSSet

}
