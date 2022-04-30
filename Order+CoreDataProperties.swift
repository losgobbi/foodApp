//
//  Order+CoreDataProperties.swift
//  
//
//  Created by Rodrigo Celso Gobbi on 5/25/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Order {

    // Keep question mark
    @NSManaged var addInfo: String?
    @NSManaged var date: NSTimeInterval
    @NSManaged var deliveryAddressId: Int32
    @NSManaged var discountInfo: String?
    @NSManaged var id: Int32
    @NSManaged var pay: String?
    @NSManaged var time: NSTimeInterval
    @NSManaged var orderClient: Client?
    @NSManaged var orderDeliveryForm: DeliveryForm?

}
