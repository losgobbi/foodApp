//
//  VendorTransformable.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 8/17/15.
//  Copyright (c) 2015 Hagen. All rights reserved.
//
//  Implements vendor specific information
//

import Foundation

class Vendor : NSObject, NSCoding {
    
    /* Line Vendor */
    private var lineColor: Int?
    
    /* Delivery Vendor */
    private var payOptions: [String]?
    
    /* Client Vendor */
    private var bkmList: [Int]?
    private var carList: [Int]?
    
    /* Product */
    private var pdGridId: Int?
    
    override init() {
        super.init()
    }
    
    required init(coder aDecoder: NSCoder) {
        lineColor = aDecoder.decodeIntegerForKey("lineColor")
        payOptions = aDecoder.decodeObjectForKey("payOptions") as? [String]
        bkmList = aDecoder.decodeObjectForKey("bkmList") as? [Int]
        carList = aDecoder.decodeObjectForKey("carList") as? [Int]
        pdGridId = aDecoder.decodeIntegerForKey("pdGridId")
        super.init()
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        if let _ = lineColor {
            aCoder.encodeInteger(lineColor!, forKey: "lineColor")
        }
        
        aCoder.encodeObject(payOptions, forKey: "payOptions")
        aCoder.encodeObject(bkmList, forKey: "bkmList")
        aCoder.encodeObject(carList, forKey: "carList")
        
        if let _ = pdGridId {
            aCoder.encodeInteger(pdGridId!, forKey: "pdGridId")
        }
    }
    
    /* Line background color */
    func setLineColor(color: Int) {
        lineColor = color
    }
    
    func getLineColor() -> Int {
        return lineColor!
    }
    
    /* Delivery provider paying options */
    func setPayOptions(opts: [String]) {
        payOptions = opts
    }
    
    func getPayOptions() -> [String] {
        return payOptions!
    }
    
    /* Client */
    func setBkmList(bk: [Int]) {
        bkmList = bk
    }
    
    func getBkmList() -> [Int]? {
        return bkmList
    }
    
    func setCarList(car: [Int]) {
        carList = car
    }
    
    func getCarList() -> [Int]? {
        return carList
    }
    
    /* Product */
    func setPdGridId(id: Int) {
        pdGridId = id
    }
    
    func getPdGridId() -> Int {
        return pdGridId!
    }
}
