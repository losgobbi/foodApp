//
//  Client+CoreDataProperties.swift
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

extension Client {

    @NSManaged var birthday: NSTimeInterval
    @NSManaged var cellPhone: String
    @NSManaged var cpf: String
    @NSManaged var email: String
    @NSManaged var fullName: String
    @NSManaged var id: Int32
    @NSManaged var lastOrderTime: NSTimeInterval
    @NSManaged var login: String
    @NSManaged var newsletter: Bool
    @NSManaged var password: String
    @NSManaged var residentialPhone: String
    @NSManaged var syncTime: NSTimeInterval
    // Keep vendor as optional
    @NSManaged var vendor: NSObject?
    @NSManaged var clientAddress: NSSet
    @NSManaged var clientBookMarks: NSSet
    @NSManaged var clientOrder: Order
    @NSManaged var clientProductList: NSSet

}
