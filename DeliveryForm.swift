//
//  DeliveryForm.swift
//  
//
//  Created by Rodrigo Celso Gobbi on 3/4/16.
//
//  Extension for handling DeliveryForm Management Object
//

import Foundation
import CoreData

class DeliveryForm: NSManagedObject {

    class func add(moc: NSManagedObjectContext) -> DeliveryForm {
        let form = NSEntityDescription.insertNewObjectForEntityForName(
            "DeliveryForm", inManagedObjectContext: moc) as! DeliveryForm
        return form
    }
    
    class func getAll(moc: NSManagedObjectContext) throws -> [DeliveryForm]? {
        let fetchReq = NSFetchRequest(entityName: "DeliveryForm")
        let forms = try moc.executeFetchRequest(fetchReq) as! [DeliveryForm]
        
        guard forms.count > 0 else {
            throw error(message: "DeliveryForm.get() not found",
                errorCode: Codes.ElementNotFound.rawValue)
        }
        
        return forms
    }
    
    class func get(moc: NSManagedObjectContext, formId: Int32) throws -> DeliveryForm? {
        let fetchReq = NSFetchRequest(entityName: "DeliveryForm")
        fetchReq.predicate = NSPredicate(format: "id = \(formId)")
        let forms = try moc.executeFetchRequest(fetchReq) as! [DeliveryForm]
        
        guard forms.count > 0 else {
            throw error(message: "DeliveryForm.get() not found id = \(formId)",
                errorCode: Codes.ElementNotFound.rawValue)
        }
        
        return forms[0]
    }
}
