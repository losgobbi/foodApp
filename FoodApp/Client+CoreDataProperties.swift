//
//  Client+CoreDataProperties.swift
//  
//
//  Created by Rodrigo Celso Gobbi on 12/7/15.
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
    @NSManaged var login: String
    @NSManaged var residentialPhone: String
    @NSManaged var syncTime: NSTimeInterval
    @NSManaged var clientAddress: NSSet
    @NSManaged var clientBookMarks: NSSet
    @NSManaged var clientOrder: Order
    @NSManaged var clientProductList: NSSet

}
