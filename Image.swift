//
//  Image+Mgmt.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 5/14/15.
//  Copyright (c) 2015 Hagen. All rights reserved.
//
//  Extension for handling Image Management Object
//

import Foundation
import CoreData

class Image: NSManagedObject {
    
    class func createImage(moc: NSManagedObjectContext) -> Image {
        let img = NSEntityDescription.insertNewObjectForEntityForName(
            "Image", inManagedObjectContext: moc) as! Image
        return img
    }
    
    class func getImageByPath(moc: NSManagedObjectContext, path: String)
        throws -> Image? {
            let fetchReq = NSFetchRequest(entityName: "Image")
            fetchReq.predicate = NSPredicate(format: "path = %@", path)
            let img = try moc.executeFetchRequest(fetchReq) as! [Image]
            
            guard img.count > 0 else {
                throw error(message: "Image.getImageByPath() not found path = \(path)",
                    errorCode: Codes.ElementNotFound.rawValue)
            }
            
            return img[0]
    }
    
    class func getDownloadedImages(moc: NSManagedObjectContext) throws -> [Image]? {
        let fetchReq = NSFetchRequest(entityName: "Image")
        fetchReq.predicate = NSPredicate(format: "sizeBytes > 0 and local != true")
        
        let imgs = try moc.executeFetchRequest(fetchReq) as! [Image]
        return imgs
    }
    
    class func getImageByStringId(moc: NSManagedObjectContext, id: String)
        throws -> Image {
            let fetchReq = NSFetchRequest(entityName: "Image")
            fetchReq.predicate = NSPredicate(format: "stringIdentifier = %@", id)
            let img = try moc.executeFetchRequest(fetchReq) as! [Image]
            
            guard img.count > 0 else {
                throw error(message: "Image.getImageByStringId() not found stringIdentifier = \(id)", errorCode: Codes.ElementNotFound.rawValue)
            }
            
            return img[0]
    }
}
