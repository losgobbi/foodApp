//
//  PersistencyManager.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 4/1/15.
//  Copyright (c) 2015 Hagen. All rights reserved.
//
//  Persistency module for the application.
//

import UIKit
import CoreData
import SwiftyJSON

class PersistencyManager : NSObject {
    private var moc: NSManagedObjectContext?

    /* control */
    private var userLogged: String = defaultUser
    private var dbReady : Bool = false
    
    override init() {
        super.init()

        /* notifications */
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector:#selector(PersistencyManager.syncData(_:)), name: FoodAppNotifications.FetchData.rawValue,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector:#selector(PersistencyManager.saveUserInfo(_:)), name: FoodAppNotifications.getUserStatus.rawValue, object: nil)
    }

    func setDataContext(mc: NSManagedObjectContext) {
        moc = mc
    }
    
    func getDataContext() -> NSManagedObjectContext {
        return moc!
    }

    func eraseDataContext() {
        moc!.reset()
    }

    func setUserLogged(login: String) {
        userLogged = login
    }
    
    func getUserLogged() -> String {
        return userLogged
    }
    
    /* Build information that is not generic */
    static func buildLineSpecific(line: Line) {
        /* background color for line */
        var color = 0x000000
        switch line.name {
        case "Light":
            color = 0x208B0F
        case "Tradicional":
            color = 0xE75C19
        case "Executiva":
            color = 0x27A8AE
        case "Sopas":
            color = 0xF8AE4B
        case "Natal":
            color = 0xd6cab0
        case "Fitness":
            color = 0xba342a
        default:
            break
        }

        let vendorInfo = Vendor()
        vendorInfo.setLineColor(color)
        line.vendor = vendorInfo
    }
    
    /* backup user data since we can lose some info during cache process */
    private func backupClientInfo() {
        do {
            let cl = try Client.get(moc!, login: userLogged)
            if let _ = cl!.vendor as? Vendor {
                /* backup already created, go further... */
                print("backup already created, go further...")
                return
            }
            
            let clientInfo = Vendor()
            var codes = [Int]()
            
            /* set car into vendor pool */
            var carList = try Client.getCar(moc!, login: userLogged)
            for i in 0..<carList!.count {
                codes.append(Int(carList![i].id))
            }
            clientInfo.setCarList(codes)

            /* set bk into vendor pool */
            codes.removeAll()
            var bkList = try Client.getBookMarks(moc!, login: userLogged)
            for i in 0..<bkList!.count {
                codes.append(Int(bkList![i].id))
            }
            clientInfo.setBkmList(codes)
            
            /* set to vendor */
            cl!.vendor = clientInfo
        } catch _ as NSError {
            print("backupClientInfo: Unable to backup user stuff")
        }
    }
    
    private func rebaseClientInfo() {
        do {
            let cl = try Client.get(moc!, login: userLogged)
            if let clientInfo = cl!.vendor as? Vendor {
                let bks = clientInfo.getBkmList()!
                for i in 0..<bks.count {
                    let pd = try? Product.get(moc!, pdCode: Int32(bks[i]))
                    /* this product was removed after cache expiration */
                    if pd == nil {
                        print("rebaseClientInfo: Unable to restore Bk, ProductId:\(bks[i]) was removed")
                        continue
                    }
                    
                    /* maybe the line was not expired */
                    let alreadyInBk = try! Client.isProductInBookMarks(moc!, login: userLogged, pd: pd!!)
                    if alreadyInBk {
                        continue
                    }

                    /* put it back */
                    try! Client.addBookMarks(moc!, login: userLogged, pd: pd!!)
                }
                
                let car = clientInfo.getCarList()!
                for i in 0..<car.count {
                    let pd = try? Product.get(moc!, pdCode: Int32(car[i]))
                    /* this product was removed after cache expiration */
                    if pd == nil {
                        print("rebaseClientInfo: Unable to restore Car, ProductId:\(car[i]) was removed")
                        continue
                    }
                    
                    /* maybe the line was not expired */
                    let alreadyInCar = try! Client.isProductInCar(moc!, login: userLogged, pd: pd!!)
                    if alreadyInCar {
                        continue
                    }
                    
                    /* put it back */
                    try! Client.addCar(moc!, login: userLogged, pd: pd!!)
                }
            }
            
            /* remove vendor */
            cl!.vendor = nil
        } catch _ as NSError {
            print("rebaseClientInfo: Unable rebase user stuff")
        }
    }
    
    func fetchFinished(url: String) -> Bool {
        
        /* to soon */
        if url == serverDeliveryForms {
            return false
        }
        
        /* if all elements are in sync and we fetched at least one valid line */
        let lineCount = try! Line.getAll(moc!)?.count
        let lineOutOfSync = try? Line.getOutOfSync(moc!)
        if lineOutOfSync == nil && lineCount > 1 {
            return true
        }
        
        return false
    }
    
    func buildBasicInfo() {
        
        /* build basic info only at the first launch */
        let syncTime = try? getUserSyncTime()
        if syncTime != nil {
            return
        }

        /*
        * create a default line. during the extract process, the product
        * may not have a valid line. We will use this for append those
        * kinds of products.
        */
        let _ = try? createDefaultLine()
    }
    
    /* build data according to the json url */
    private func buildData(data: JSON, url: String, jsonArgs: [String: AnyObject]) {
        var wake_up_app: Bool = false
        
        /* store current user */
        backupClientInfo()
        
        /* 
         * XXX Be careful here! This function is reentrant so avoid
         * adding the same elements again during the parser actions.
         * Some parsing actions handles with cache mechanism.
         */
        
        /* parse json data according to url */
        switch url {
        case serverJsonLines:
            
            /* check line cache */
            validateLineCache(moc!, arrayEntry: data.dictionary!)
            
            /* build line */
            extractLines(moc!, arrayEntry: data.dictionary!)
            break
        case serverJsonProducts:
            try! extractProducts(moc!, arrayEntry: data.dictionary!, reqArgs: jsonArgs)
            break
        case serverDeliveryForms:
            extractDeliveryForms(moc!, arrayEntry: data.dictionary!)
            break
        default:
            break
        }
        
        if fetchFinished(url) {
            /* always update sync to defaultUser */
            if let cl = try? Client.get(moc!, login: defaultUser) {
                cl!.syncTime = NSDate().timeIntervalSinceReferenceDate
            } else {
                Client.addSyncTime(moc!)
            }
            
            dbReady = true
            wake_up_app = true
        }

        /* sign app that we are ready */
        if wake_up_app {
            printReport()

            /* replay user info */
            rebaseClientInfo()
            
            /* XXX remove duplicated clients */
            removeInvalidUsers()
            
            sanitizeJsonProduct(moc!)
            
            NSNotificationCenter.defaultCenter().postNotificationName(
                FoodAppNotifications.DataReady.rawValue, object: self, userInfo: nil)
        }
    }
    
    /* Default things */
    private func createDefaultLine() throws {
        let dftLine = Line.add(moc!)
        dftLine.id = Int32(defaultInternalLine)
        dftLine.name = "FoodApp Line"
        dftLine.desc = "FoodApp Line Desc"
        dftLine.status = 1
    }
    
    /* General methods */
    func getProductList(line: Line) throws -> [Product]? {
        let pdList = try Line.getProductList(moc!,line: line)
        return pdList
    }

    func getProductPromoList() throws -> [Product]? {
        return try Product.getPromo(moc!)
    }
    
    func getProductImage(pd: Product) -> UIImage? {
        /* Its a local image */
        if pd.productImage.local {
            return UIImage(named: pd.productImage.path)
        }
        /* Image was saved */
        if let imgBin = pd.productImage.image as NSData? {
            return UIImage(data: imgBin)
        }
        /* Image was not found */
        return nil
    }
    
    func getRandomLine() throws -> Line {
        let line = try Line.getRandom(moc!, count: 1)
        return line![0]
    }
    
    func getLines() throws -> [Line] {
        return try Line.getAll(moc!)!
    }
    
    func getLine(code: Int) throws -> Line {
        return try Line.get(moc!,lineCode: Int32(code))!
    }
    
    func getLineColor(line: Line) -> Int {
        let vendorInfo = line.vendor as! Vendor
        return vendorInfo.getLineColor()
    }
    
    func getLineUImage(line: Line, id: String) throws -> UIImage? {
        var imgName = [String]()
        imgName.append(line.name)
        replace_char(&imgName, token_source: " ", token_dst: "")
        
        let lineImg = try Image.getImageByPath(moc!, path: imgName[0] + id)
        if lineImg != nil {
            return UIImage(named: lineImg!.path)
        }
        
        /* Image was not found */
        return nil
    }
    
    func getImageByStringId(id: String) throws -> Image {
        return try Image.getImageByStringId(moc!, id: id)
    }
    
    func getProduct(pdCode: Int) throws -> Product? {
        return try Product.get(moc!, pdCode: Int32(pdCode))
    }
    
    func countDownloadedImages() throws -> Int {
        let imgs = try Image.getDownloadedImages(moc!)
        if let img = imgs {
            return img.count
        }
        return 0
    }
    
    func sizeOfDownloadedImages() throws -> Int {
        var totalBytes: Int = 0
        let imgs = try Image.getDownloadedImages(moc!)
        if let img = imgs {
            for i in 0..<img.count {
                totalBytes += Int(img[i].sizeBytes)
            }
        }
        return totalBytes
    }
    
    func getDeliveryForms() throws -> [DeliveryForm]? {
        return try DeliveryForm.getAll(moc!)
    }
    
    func getDbState() -> Bool {
        return dbReady
    }
    
    func addAddress() -> Address? {
        return Address.add(moc!)
    }
    
    func removeAddress(addr: String) throws {
        return try Address.rem(moc!, address: addr)
    }
    
    func removeAllAddresses() throws {
        return try Address.remAll(moc!)
    }
    
    func getOrderIntervals() -> [String] {
        return [ "9h - 11h", "12h - 14h", "14h - 16h", "16h - 18h" ]
    }

    func getOrderHalfIntervals(interval: String) -> String {
        let intervals = getOrderIntervals()
        let halfIntervals =  [ "10", "13", "15", "17"]
        let index = intervals.indexOf(interval)
        return halfIntervals[index!]
    }
    
    /* User Information */
    func getUserSyncTime() throws -> NSTimeInterval? {
        /* always use the defaultUser to check the sync time */
        if let cl = try Client.get(moc!, login: defaultUser) {
            return cl.syncTime
        }
        return nil
    }
    
    func addUserAddress(address: Address) throws {
        try Client.addAddress(moc!, login: userLogged, address: address)
    }
    
    func addUserAddress(login: String, address: Address) throws {
        try Client.addAddress(moc!, login: login, address: address)
    }
    
    func remUserAddress(address: Address) throws {
        try Client.remAddress(moc!, login: userLogged, address: address)
    }
    
    func getUserAddresses() throws -> [Address] {
        return try Client.getAddresses(moc!, login: userLogged)!
    }
    
    func getUserBookMarks() throws -> [Product] {
        return try Client.getBookMarks(moc!, login: userLogged)!
    }
    
    func addUserBookMark(pd: Product) throws {
        try Client.addBookMarks(moc!, login: userLogged, pd: pd)
    }

    func remUserBookMark(pd: Product) throws {
        try Client.remBookMarks(moc!, login: userLogged, pd: pd)
    }

    func isProductInBookMarks(pd: Product) throws -> Bool {
        return try Client.isProductInBookMarks(moc!, login: userLogged, pd: pd)
    }

    func addProductToUserCar(pd: Product) throws {
        try Client.addCar(moc!, login: userLogged, pd: pd)
    }
    
    func addAnyProductToUserCar(pd: Product, num: Int) throws {
        try Client.addAnyCar(moc!, login: userLogged, pd: pd, num: num)
    }
    
    func getUserProductCar() throws -> [Product] {
        return try Client.getCar(moc!, login: userLogged)!
    }

    func isProdutcInCar(pd: Product) throws -> Bool {
        return try Client.isProductInCar(moc!, login: userLogged, pd: pd)
    }
    
    func getCarLines() throws -> [Line] {
        return try Client.getCarLines(moc!, login: userLogged)
    }
    
    func remProductFromUserCar(pd: Product) throws {
        try Client.removeFromCar(moc!, login: userLogged, pd: pd)
    }
    
    func remUserCar() throws {
        try Client.removeCar(moc!, login: userLogged)
    }
    
    func removeAllCars() {
        Client.removeAllCars(moc!)
    }
    
    func buildUserOrderContainer() throws -> Order {
        return try Order.addOrder(moc!, login: userLogged)
    }
    
    func getUserOrder() throws -> Order? {
        let cl = try Client.get(moc!, login: userLogged)!
        return cl.clientOrder
    }
    
    func remUserOrder() throws {
        try Order.remOrder(moc!, login: userLogged)
    }
    
    //TODO why throws?
    func addUser() throws -> Client? {
        return Client.add(moc!)
    }
    
    func getUser() throws -> Client? {
        return try Client.get(moc!, login: userLogged)
    }

    func getUser(login: String) throws -> Client? {
        return try Client.get(moc!, login: login)
    }
    
    func removeUser(login: String) throws {
        return try Client.rem(moc!, login: login)
    }
    
    func removeInvalidUsers() {
        let cls = Client.getAll(moc!)
        var duplicatedLogins = NSSet()

        /* build all duplicated logins */
        for i in 0..<cls.count {
            if cls[i].login == defaultUser {
                continue
            }
            
            /* if its not duplicated */
            let dupElem = try! Client.countLogin(moc!, login: cls[i].login)
            if dupElem <= 1 {
                continue
            }
            
            duplicatedLogins = duplicatedLogins.setByAddingObject(cls[i].login)
        }
        
        /* remove all */
        let logins = duplicatedLogins.allObjects as! [String]
        for i in 0..<logins.count {
            try! Client.rem(moc!, login: logins[i])
        }
    }

    /* notification handlers */
    func syncData(notification: NSNotification) {
        if let userInfo = notification.userInfo as? [String: AnyObject] {
            if let jsonUrl = userInfo["jsonUrl"] as? String {
                let args = userInfo["jsonArgs"] as! [String: AnyObject]
                buildData(JSON(userInfo["jsonRaw"]!), url: jsonUrl, jsonArgs: args)
            } else {
                /* unable to parse json, wake up the app */
                NSNotificationCenter.defaultCenter().postNotificationName(
                    FoodAppNotifications.DataReady.rawValue, object: self, userInfo: notification.userInfo)
            }
        }
    }
    
    /* Restore actions */
    func getAllProducts() throws -> [Product]? {
        return try Product.getAll(moc!)
    }
    
    func printReport() {
        print("### PM Data Report ###")
        let lines = try! Line.getAll(moc!)!
        var totalPds: Int = 0
        print("Nro of Lines: \(lines.count)")
        for i in 0..<lines.count {
            let pds = try! Line.getProductList(moc!, line: lines[i])!
            print("\tLine: '\(lines[i].name)' ProductCount(status=1): '\(pds.count)'")
            totalPds += pds.count
        }
        let dflLine = try! Line.get(moc!, lineCode: Int32(defaultInternalLine))!
        let pds = try! Line.getProductList(moc!, line: dflLine)!
        totalPds += pds.count
        print("\tLine: '\(dflLine.name)' ProductCount(status=1): '\(pds.count)'")
        print("\t----------------------------------------")
        print("\tTotal ProductCount: '\(totalPds)'")
        print("\n")
    }
    
    func saveUserInfo(notification: NSNotification) {
        let userInfo = notification.userInfo as! [String: AnyObject]
        let status = userInfo["status"] as! Int
        
        switch status {
        case 200:
            break;
        default:
            error(message: "saveUserInfo(): request for user details failed. Code = '\(status)'",
                errorCode: Codes.FetchUserInfoFailed.rawValue)
            NSNotificationCenter.defaultCenter().postNotificationName(
                FoodAppNotifications.UserSynchronized.rawValue, object: self, userInfo: userInfo)
            return
        }
        
        let serverAddresses = userInfo["addresses"]
        let user = userInfo["user"]
        
        /* Save the logged user info */
        do {
            self.setUserLogged(user!["email"] as! String)
            
            /* recover elements from newUserVC/loginVC */
            let client = try self.getUser()
            var addresses = try self.getUserAddresses()
            
            client?.login = user!["email"] as! String
            client?.fullName = user!["nome"] as! String
            client?.cellPhone = user!["celular"] as! String
            client?.residentialPhone = user!["telefone"] as! String
            client?.cpf = user!["cpf"] as! String
            client?.email = user!["email"] as! String
            client?.id = Int32(user!["id"] as! String)!
            client?.newsletter = false
            
            if (serverAddresses?.count > addresses.count) {
                let newAddress = Address.add(moc!)
                try Client.addAddress(moc!, login: userLogged, address: newAddress)
            }
            
            if (serverAddresses?.count < addresses.count) {
                try Client.remAddress(moc!, login: userLogged, address: addresses.last!)
            }
            
            addresses = try self.getUserAddresses()

            var i = 0
            for entry in serverAddresses as! [[String: AnyObject]] {
                addresses[i].address = entry["endereco"] as? String
                addresses[i].neighborhood = entry["bairro"] as? String
                addresses[i].number = Int((entry["numero"] as? String)!)
                addresses[i].zipcode = entry["cep"] as? String
                addresses[i].city = entry["cidade"] as? String
                addresses[i].id = Int((entry["id"] as? String)!)
                addresses[i].state = entry["uf"] as? String
                addresses[i].complement = entry["complemento"] as? String
                
                i += 1
                if (i == serverAddresses!.count) {
                    break
                }
            }

            try Client.transferBookmarks(moc!, from: defaultUser, to: userLogged)
            try Client.transferCar(moc!, from: defaultUser, to: userLogged)
            try Client.transferOrder(moc!, from: defaultUser, to: userLogged)
        } catch {
            print("saveUserInfo(): error while saving user info")
            return
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(
            FoodAppNotifications.UserSynchronized.rawValue, object: self, userInfo: userInfo)
    }
}
