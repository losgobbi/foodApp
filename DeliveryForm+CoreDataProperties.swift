//
//  DeliveryForm+CoreDataProperties.swift
//  
//
//  Created by Rodrigo Celso Gobbi on 3/26/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension DeliveryForm {

    @NSManaged var desc: String
    @NSManaged var id: Int32
    @NSManaged var name: String
    @NSManaged var price: Float
    @NSManaged var status: Int16
    @NSManaged var time: String
    @NSManaged var type: String
    @NSManaged var deliveryFormDeliveryProvider: DeliveryProvider
    @NSManaged var deliveryFormOrder: Order

}
