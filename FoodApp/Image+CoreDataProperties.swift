//
//  Image+CoreDataProperties.swift
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

extension Image {

    @NSManaged var dir: String?
    @NSManaged var expectedSize: Int32
    @NSManaged var file: String?
    @NSManaged var format: String?
    @NSManaged var image: NSData?
    @NSManaged var local: Bool
    @NSManaged var path: String?
    @NSManaged var sizeBytes: Int32
    @NSManaged var uploadedDate: NSTimeInterval
    @NSManaged var imageLine: Line?
    @NSManaged var imageProduct: Product?
    @NSManaged var imageProvider: DeliveryProvider?

}
