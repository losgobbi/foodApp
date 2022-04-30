//
//  MetaData.swift
//  
//
//  Created by Rodrigo Celso Gobbi on 3/8/16.
//
//  Extension for handling MetaData Management Object
//

import Foundation
import CoreData


class MetaData: NSManagedObject {

    class func add(moc: NSManagedObjectContext) -> MetaData {
        let metaInfo = NSEntityDescription.insertNewObjectForEntityForName(
            "MetaData", inManagedObjectContext: moc) as! MetaData
        return metaInfo
    }

    class func get(moc: NSManagedObjectContext) throws -> MetaData? {
        let fetchReq = NSFetchRequest(entityName: "MetaData")
        let metaInfo = try moc.executeFetchRequest(fetchReq) as! [MetaData]
        
        guard metaInfo.count > 0 else {
            throw error(message: "MetaData.get() not found",
                errorCode: Codes.ElementNotFound.rawValue)
        }

        // only one meta per request
        guard metaInfo.count < 2 else {
            throw error(message: "MetaData.get() meta exceeded",
                errorCode: Codes.MetaDataExceeded.rawValue)
        }
        
        return metaInfo[0]
    }
    
    class func rem(moc: NSManagedObjectContext, metaInfo: MetaData) {
        moc.deleteObject(metaInfo)
    }
}
