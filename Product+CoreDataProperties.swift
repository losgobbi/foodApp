//
//  Product+CoreDataProperties.swift
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

extension Product {

    @NSManaged var attrs: String
    @NSManaged var id: Int32
    @NSManaged var desc: String
    @NSManaged var discount: Bool
    @NSManaged var discountPrice: Float
    @NSManaged var fullDesc: String
    @NSManaged var hint: String
    @NSManaged var name: String
    @NSManaged var obs: String
    @NSManaged var price: Float
    @NSManaged var productListCount: Int16
    @NSManaged var rate: NSDecimalNumber
    @NSManaged var status: Int16
    @NSManaged var vendor: NSObject
    @NSManaged var productCache: Cache
    @NSManaged var productCategory: Category
    @NSManaged var productCharacteristic: NSSet
    @NSManaged var productClientBookMarks: Client
    @NSManaged var productClientProductList: Client
    @NSManaged var productImage: Image
    @NSManaged var productIngredient: NSSet
    @NSManaged var productLine: Line
    @NSManaged var productLot: Lot
    @NSManaged var productPacking: Packing

}
