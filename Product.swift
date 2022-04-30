//
//  ProductMgmt.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 5/8/15.
//  Copyright (c) 2015 Hagen. All rights reserved.
//
//  Extension for handling Product Management Object
//

import Foundation
import CoreData

class Product: NSManagedObject {
    
    class func add(moc: NSManagedObjectContext) -> Product {
        let pd = NSEntityDescription.insertNewObjectForEntityForName(
            "Product", inManagedObjectContext: moc) as! Product
        return pd
    }
    
    class func get(moc: NSManagedObjectContext, pdCode: Int32) throws -> Product? {
        let fetchReq = NSFetchRequest(entityName: "Product")
        fetchReq.predicate = NSPredicate(format: "id = \(pdCode) and status = 1")
        
        let products = try moc.executeFetchRequest(fetchReq) as! [Product]
        
        guard products.count > 0 else {
            throw error(message: "Product.get() not found",
                errorCode: Codes.ElementNotFound.rawValue)
        }
        
        return products[0]
    }
    
    /* get all promo products */
    class func getPromo(moc: NSManagedObjectContext) throws -> [Product]? {
        let fetchReq = NSFetchRequest(entityName: "Product")
        fetchReq.predicate = NSPredicate(format: "discount = true and status = 1")
        
        let products = try moc.executeFetchRequest(fetchReq) as! [Product]
        
        guard products.count > 0 else {
            throw error(message: "Product.getPromo() not found",
                errorCode: Codes.ElementNotFound.rawValue)
        }
        
        return products
    }
    
    class func rem(moc: NSManagedObjectContext, pd: Product) {
        moc.deleteObject(pd)
    }
    
    /* get count radom */
    class func getRandom(moc: NSManagedObjectContext, count: Int) throws -> [Product]? {
        var pdMap = [Int]()
        var randomMap = [Int]()
        var randomIdx: Int
        
        /* get all elements and fill theirs codes */
        let fetchReq = NSFetchRequest(entityName: "Product")
        
        var pds = try moc.executeFetchRequest(fetchReq) as! [Product]
        for i in 0..<pds.count {
            pdMap.append(Int(pds[i].id))
        }
        
        /* build random map */
        for _ in 0..<count {
            randomIdx = getRandomNumber(pdMap.count)
            randomMap.append(pdMap[randomIdx])
            /* remove idx */
            pdMap.removeAtIndex(randomIdx)
        }
        
        /* build clause */
        var set = [String]()
        let replace = ["[", "]"]
        set.append(randomMap.debugDescription)
        replace_multiplechars(&set, token_source: replace, token_dst: "")
        
        /* fetch random objects */
        fetchReq.predicate = NSPredicate(format: "(id IN {\(set[0])}) and status = 1")
        pds = try moc.executeFetchRequest(fetchReq) as! [Product]
        return pds
    }
    
    class func getAll(moc: NSManagedObjectContext) throws -> [Product]? {
        let fetchReq = NSFetchRequest(entityName: "Product")
        fetchReq.predicate = NSPredicate(format: "status = 1")
        let products = try moc.executeFetchRequest(fetchReq) as! [Product]
        return products
    }
}
