//
//  Line+Mgmt.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 5/13/15.
//  Copyright (c) 2015 Hagen. All rights reserved.
//
//  Extension for handling Line Management Object
//

import Foundation
import CoreData

class Line: NSManagedObject {
    
    class func add(moc: NSManagedObjectContext) -> Line {
        let line = NSEntityDescription.insertNewObjectForEntityForName(
            "Line", inManagedObjectContext: moc) as! Line
        return line
    }
    
    class func get(moc: NSManagedObjectContext, lineCode: Int32) throws -> Line? {
        let fetchReq = NSFetchRequest(entityName: "Line")
        fetchReq.predicate = NSPredicate(format: "id = \(lineCode) and status = 1")
        let line = try moc.executeFetchRequest(fetchReq) as! [Line]
        
        guard line.count > 0 else {
            throw error(message: "Line.get() not found id = \(lineCode)",
                errorCode: Codes.ElementNotFound.rawValue)
        }
        
        return line[0]
    }
    
    class func rem(moc: NSManagedObjectContext, line: Line) {
        moc.deleteObject(line)
    }
    
    class func addImage(moc: NSManagedObjectContext, line: Line,
        pd: Image) {
            let cImage = line.mutableSetValueForKeyPath("lineImage")
            cImage.addObject(pd)
    }
    
    class func addProduct(moc: NSManagedObjectContext, line: Line,
        pd: Product) {
            let pdList = line.mutableSetValueForKeyPath("lineProductList")
            pdList.addObject(pd)
    }
    
    class func removeProduct(moc: NSManagedObjectContext, line: Line,
        pd: Product) {
            let pdList = line.mutableSetValueForKeyPath("lineProductList")
            pdList.removeObject(pd)
    }
    
    class func getProductList(moc: NSManagedObjectContext, line:
        Line) throws -> [Product]? {
            let lineElem = try get(moc, lineCode: line.id)
            var pdActiveList = [Product]()

            /* check for invalid line */
            guard let lineValid = lineElem else {
                throw error(message: "Product.getProductList() invalid Line",
                    errorCode: Codes.ElementNotFound.rawValue)
            }
            
            let pdList = lineValid.mutableSetValueForKeyPath("lineProductList").allObjects as! [Product]
            for i in 0..<pdList.count {
                let pd = pdList[i]
                if pd.status == 1 {
                    pdActiveList.append(pd)
                }
            }
            return pdActiveList
    }
    
    /* get count radom */
    class func getRandom(moc: NSManagedObjectContext, count: Int) throws -> [Line]? {
        var linesMap = [Int]()
        var randomMap = [Int]()
        var randomIdx: Int
        
        /* get all elements and fill theirs codes */
        let fetchReq = NSFetchRequest(entityName: "Line")
        var lines = try moc.executeFetchRequest(fetchReq) as! [Line]
        
        for i in 0..<lines.count {
            /* for now, we will dismiss the default line for random choice */
            if Int(lines[i].id) == defaultInternalLine {
                continue
            }
            linesMap.append(Int(lines[i].id))
        }
        
        /* build random map */
        for _ in 0..<count {
            randomIdx = getRandomNumber(linesMap.count)
            randomMap.append(linesMap[randomIdx])
            /* remove idx */
            linesMap.removeAtIndex(randomIdx)
        }
        
        /* build clause */
        var set = [String]()
        let replace = ["[", "]"]
        set.append(randomMap.debugDescription)
        replace_multiplechars(&set, token_source: replace, token_dst: "")
        
        /* fetch random objects */
        fetchReq.predicate = NSPredicate(format: "(id IN {\(set[0])}) and status = 1")
        lines = try moc.executeFetchRequest(fetchReq) as! [Line]
        return lines
    }
    
    /* get window, date should be in the interval start-stop */
    class func getWindow(moc: NSManagedObjectContext, date: NSDate) throws -> [Line]? {
        let fetchReq = NSFetchRequest(entityName: "Line")
        fetchReq.predicate = NSPredicate(format:
            "startDate <= %@ AND stopDate >= %@", date, date)
        let lines = try moc.executeFetchRequest(fetchReq) as! [Line]
        return lines
    }
    
    class func getAll(moc: NSManagedObjectContext) throws -> [Line]? {
        let fetchReq = NSFetchRequest(entityName: "Line")
        /* we do not need the internal line */
        fetchReq.predicate = NSPredicate(format: "NOT (id IN {\(defaultInternalLine)}) and status = 1")
        let order = NSSortDescriptor(key: "name", ascending: true)
        fetchReq.sortDescriptors = [order]
        let categories = try moc.executeFetchRequest(fetchReq) as! [Line]
        return categories
    }
    
    class func getOutOfSync(moc: NSManagedObjectContext) throws -> Line {
        let fetchReq = NSFetchRequest(entityName: "Line")
        fetchReq.predicate = NSPredicate(format: "syncedProducts = false and NOT (id IN {\(defaultInternalLine)})")
        let line = try moc.executeFetchRequest(fetchReq) as! [Line]
        
        guard line.count > 0 else {
            throw error(message: "Line.get() OutOfSync not found",
                errorCode: Codes.ElementNotFound.rawValue)
        }
        
        return line[0]
    }
}
