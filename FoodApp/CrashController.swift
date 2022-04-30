//
//  CrashController.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 12/19/15.
//  Copyright © 2015 Hagen. All rights reserved.
//

import UIKit
import Crashlytics
import CoreData

class CrashController: NSObject, CrashlyticsDelegate {
    
    /* Api reference */
    private var api = FoodApp.sharedInstance

    /* Coredata context */
    private var moc: NSManagedObjectContext?
        
    func crashlyticsDidDetectReportForLastExecution(report: CLSReport, completionHandler: (Bool) -> Void) {
        
        /* XXX the app is not ready so cant use api to get ctx  */
        moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        api.setManagedContext(moc!)

        do {
            let user = try api.getUser()
            
            /* bk codes */
            let bks = try api.getUserBookMarks()
            var bkCodes = NSSet()
            for i in 0..<bks.count {
                bkCodes = bkCodes.setByAddingObject(Int(bks[i].id))
            }
            report.setObjectValue(bkCodes,
                forKey: "api.getUserBookMarks()")
            
            /* car codes */
            let carList = try api.getUserProductCar()
            var carCodes = NSSet()
            for i in 0..<carList.count {
                carCodes = carCodes.setByAddingObject(Int(carList[i].id))
            }
            report.setObjectValue(carCodes,
                forKey: "api.getUserProductCar()")
            
            /* car line codes */
            let carLine = try api.getUserLineCar()
            var carLineCodes = NSSet()
            for i in 0..<carLine.count {
                carLineCodes = carLineCodes.setByAddingObject(Int(carLine[i].id))
            }
            report.setObjectValue(carLineCodes,
                forKey: "api.getUserLineCar()")
            
            /* user logged */
            let (logged, _, _) = try api.userIsLogged()
            report.setObjectValue(logged, forKey: "api.userIsLogged()")
            
            /* order */
            let userOrder = try api.getUserOrder()
            var order = "api.getUserOrder(): There wasn't a order"
            if let _ = userOrder {
                order = "api.getUserOrder(): There was a order"
            }
            report.setObjectValue(order, forKey: "api.getUserOrder()")
            
            /* user sync time */
            let syncTime = timeToStr(NSDate(
                timeIntervalSinceReferenceDate: user!.syncTime))
            report.setObjectValue(syncTime, forKey: "user.syncTime")
            
            /* count downloaded images */
            report.setObjectValue(try api.countDownloadedImages(),
                forKey: "api.countDownloadedImages()")
            
            /* size of images */
            report.setObjectValue(try api.sizeOfDownloadedImages(),
                forKey: "api.sizeOfDownloadedImages() / bytes")
            
            /* restore errors from api */
            let defaults = NSUserDefaults.standardUserDefaults()
            let errorsBuffer = defaults.objectForKey("FoodAppErrors") as? [String] ?? [String]()
            
            report.setObjectValue(errorsBuffer.count,
                forKey: "api.errorsCount")

            for i in 0..<errorsBuffer.count {
                CLSNSLogv("\(errorsBuffer[i])", getVaList([""]))
            }
        } catch let error as NSError {
            CLSNSLogv("There is no object graph, the app crashed at the startup.", getVaList([""]))
            print("Unable to append information to CrashReport. Error = \(error)")
        }
        
        /* send report */
        completionHandler(true)
    }
}
