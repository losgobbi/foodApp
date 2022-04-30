//
//  Address+CoreDataProperties.swift
//  
//
//  Created by Rodrigo Celso Gobbi on 5/24/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Address {

    @NSManaged var address: String?
    @NSManaged var addressForCharge: NSNumber?
    @NSManaged var city: String?
    @NSManaged var complement: String?
    @NSManaged var id: NSNumber?
    @NSManaged var neighborhood: String?
    @NSManaged var number: NSNumber?
    @NSManaged var state: String?
    @NSManaged var zipcode: String?
    @NSManaged var addressCache: Address?
    @NSManaged var addressClient: Client?
    @NSManaged var addressDelivery: DeliveryProvider?

}
