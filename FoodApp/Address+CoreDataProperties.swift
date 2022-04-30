//
//  Address+CoreDataProperties.swift
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

extension Address {

    @NSManaged var address: String
    @NSManaged var city: String
    @NSManaged var complement: Int16
    @NSManaged var neighborhood: String
    @NSManaged var number: Int16
    @NSManaged var state: String
    @NSManaged var zipcode: String
    @NSManaged var addressClient: Client
    @NSManaged var addressDelivery: DeliveryProvider

}
