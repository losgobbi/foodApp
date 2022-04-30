//
//  FoodApp.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 4/1/15.
//  Copyright (c) 2015 Hagen. All rights reserved.
//
//  The FoodApp API hides internal details for the entire app using the
//  facade pattern. This library uses it's internal classes (WSCl, PM, ...)
//  to answer the methods.
//

import UIKit
import CoreData

class FoodApp : NSObject {
    
    /* subsystems */
    private let persistencyManager: PersistencyManager
    private let wsClient: WebServiceClient
    private let secGen: SecretGen
    
    /* tricky to use singleton pattern */
    class var sharedInstance: FoodApp {
        struct Singleton {
            static let instance = FoodApp()
        }
        return Singleton.instance
    }
    
    override init() {
        persistencyManager = PersistencyManager()
        wsClient = WebServiceClient()
        secGen = SecretGen()
        
        super.init()
        
        /* notifications */
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector:#selector(FoodApp.getImage(_:)), name: FoodAppNotifications.ImageNotification.rawValue, object: nil)
    }
    
    /* Persistency Manager */
    func setManagedContext(moc: NSManagedObjectContext) {
        persistencyManager.setDataContext(moc)
    }
    
    func getManagedContext() -> NSManagedObjectContext {
        return persistencyManager.getDataContext()
    }
    
    func eraseManagedContext() {
        persistencyManager.eraseDataContext()
    }
    
    func getLine(code: Int) throws -> Line {
        return try persistencyManager.getLine(code)
    }
    
    func getLines() throws -> [Line] {
        return try persistencyManager.getLines()
    }
    
    func getRandomLine() throws -> Line {
        return try persistencyManager.getRandomLine()
    }
    
    func getLineColor(line: Line) -> Int {
        return persistencyManager.getLineColor(line)
    }
    
    func getProductList(line: Line) throws -> [Product]? {
        return try persistencyManager.getProductList(line)
    }
    
    func getProductPromoList() throws -> [Product]? {
        return try persistencyManager.getProductPromoList()
    }

    //TODO, check if less than initial number.
    //TODO, restore algorithm
    func getInitialProducts(elements: Int) throws -> [Product] {
        var pds = [Product]()
        
        try pds = persistencyManager.getAllProducts()!
        return pds
    }
    
    func getImage(notification: NSNotification) {
        let userInfo = notification.userInfo as! [String: AnyObject]
        if let imageView = userInfo["imageView"] as! UIImageView? {
            if let product = userInfo["product"] as! Product? {
                let pdImage = persistencyManager.getProductImage(product)
                if (pdImage == nil) {
                    wsClient.getProductImage(product, imgView: imageView)
                } else {
                    imageView.image = pdImage
                }
            } else if let line = userInfo["line"] as! Line? {
                /*
                 * Getting a LineImage is different from a productImage.
                 * First, we check for UImage object for path=line.nameLine (legacy
                 * mode used as local images). If we cant find it, search for the
                 * Image object using stringId=line.nameLine, since we need the
                 * Image.path to pass through the ws request.
                 */
                let lineImage = try? persistencyManager.getLineUImage(line, id: "Line")
                if (lineImage == nil) {
                    let img = try? persistencyManager.getImageByStringId(line.name + "Line")
                    if (img != nil && img?.image.length == 0) {
                        wsClient.getFilterLineImage(img!, imgView: imageView)
                    } else {
                        if let imgBin = img?.image as NSData? {
                            imageView.image = UIImage(data: imgBin)
                        }
                    }
                } else {
                    imageView.image = lineImage!
                }
            } else if let line = userInfo["lineProduct"] as! Line? {
                do {
                    let lineImage = try persistencyManager.getLineUImage(line, id: "Product")
                    imageView.image = lineImage
                } catch let pmError as NSError {
                    error(message: "getLineImage(): Fail to get Line Image. Id = \(line.name + " - Line"). Error = '\(pmError)'",
                        errorCode: Codes.ElementNotFound.rawValue)
                    return
                }
            }
        }
    }
    
    func getProduct(pdCode: Int) throws -> Product? {
        return try persistencyManager.getProduct(pdCode)
    }
    
    func countDownloadedImages() throws -> Int {
        return try persistencyManager.countDownloadedImages()
    }
    
    func sizeOfDownloadedImages() throws -> Int {
        return try persistencyManager.sizeOfDownloadedImages()
    }
    
    func getDeliveryForms() throws -> [DeliveryForm]? {
        return try persistencyManager.getDeliveryForms()
    }
    
    func getDbState() -> Bool {
        return persistencyManager.getDbState()
    }
    
    func addAddress() -> Address? {
        return persistencyManager.addAddress()
    }
    
    func removeAddress(addr: String) throws {
        return try persistencyManager.removeAddress(addr)
    }
    
    func removeAllAddresses() throws {
        return try persistencyManager.removeAllAddresses()
    }
    
    func getOrderIntervals() -> [String] {
        return persistencyManager.getOrderIntervals()
    }
    
    func getOrderHalfIntervals(interval: String) -> String {
        return persistencyManager.getOrderHalfIntervals(interval)
    }
    
    /* User */
    func addUserBookMark(pd: Product) throws {
        return try persistencyManager.addUserBookMark(pd)
    }

    func remUserBookMark(pd: Product) throws {
        return try persistencyManager.remUserBookMark(pd)
    }
    
    func addUserAddress(address: Address) throws {
        return try persistencyManager.addUserAddress(address)
    }
    
    func addUserAddress(login: String, address: Address) throws {
        return try persistencyManager.addUserAddress(login, address: address)
    }
    
    func remUserAddress(address: Address) throws {
        return try persistencyManager.remUserAddress(address)
    }
    
    func getUserAddresses() throws -> [Address] {
        return try persistencyManager.getUserAddresses()
    }
    
    func getUserBookMarks() throws -> [Product] {
        return try persistencyManager.getUserBookMarks()
    }

    func isProductInBookMarks(pd: Product) throws -> Bool {
        return try persistencyManager.isProductInBookMarks(pd)
    }

    func addProductToUserCar(pd: Product) throws {
        try persistencyManager.addProductToUserCar(pd)
    }
    
    func addProductToUserCar(pd: Product, num: Int) throws {
        try persistencyManager.addAnyProductToUserCar(pd, num: num)
    }
    
    func getUserProductCar() throws -> [Product] {
        return try persistencyManager.getUserProductCar()
    }
    
    func isProductInCar(pd: Product) throws -> Bool {
        return try persistencyManager.isProdutcInCar(pd)
    }
    
    func getUserLineCar() throws -> [Line] {
        return try persistencyManager.getCarLines()
    }
    
    func remProductFromUserCar(pd: Product) throws {
        try persistencyManager.remProductFromUserCar(pd)
    }
    
    func remUserCar() throws {
        try persistencyManager.remUserCar()
    }
    
    func buildUserOrderContainer() throws -> Order {
        return try persistencyManager.buildUserOrderContainer()
    }
    
    func getUserOrder() throws -> Order? {
        return try persistencyManager.getUserOrder()
    }
    
    func remUserOrder() throws {
        try persistencyManager.remUserOrder()
    }
    
    func userIsLogged() throws -> (expired: Bool, login: String?, token: String?) {
        let expired = try secGen.tokenExpired()

        if (expired.expired == true) {
            return (false, nil, nil)
        } else {
            return (true, expired.login, expired.token)
        }
    }
    
    func userAuthentication(login: String)  {
        persistencyManager.setUserLogged(login)
    }
    
    func userAuthentication(login: String, token: String, expireDate: String) throws {
        try secGen.erasePasswords()
        try secGen.createPasswdToken(login, userToken: token, expireDate: expireDate)
        
        persistencyManager.setUserLogged(login)
    }

    func userUnauthenticate() throws {
        //TODO For n users, we cant remove all
        try secGen.erasePasswords()
        persistencyManager.setUserLogged(defaultUser)
        
        /* There is no user logged, clean all cars since its a fresh start */
        persistencyManager.removeAllCars()
    }
    
    //TODO multi session
    func removeAllCars() {
        /*
         * client is going back to defaultUser, but there may be
         * some produts over the last logged car (or over others cars).
         * This is uncommon, because the user should have already sent
         * the order to the server.
         *
         * In such uncommon cases, we choose to clean all the cars since the
         * client will start filling it again over defaultUser.
         * Furthermore, if we do not do that, we could have a scenario with
         * a different number of products between defaultUser/loggerUser which
         * does not make sense.
         */
        persistencyManager.removeAllCars()        
    }
    
    func validateUserCreation(user: Client, address: Address) {
        wsClient.pushCreateUserData(serverCreateUserPath, user: user, address: address)
    }

    func validateUserAddAddress(user: Client, address: Address) {
        wsClient.pushAddUserAddress(serverAddUserAddressPath, user: user, address: address)
    }
    
    func addUser() throws -> Client? {
        return try persistencyManager.addUser()
    }

    func getUser() throws -> Client? {
        return try persistencyManager.getUser()
    }

    func getUser(login: String) throws -> Client? {
        return try persistencyManager.getUser(login)
    }
    
    func removeUser(login: String) throws {
        return try persistencyManager.removeUser(login)
    }
    
    func getUserLogged() -> String {
        return persistencyManager.getUserLogged()
    }

    /* Web interface */
    func checkNetwork() -> Bool {
        return IJReachability.isConnectedToNetwork()
    }
    
    func fetchInitialData() {
        persistencyManager.buildBasicInfo()
        
        /* we can append requests here, but keep fetchFinished() synced too */
        let jsonArgs = WebServiceJsonArgs()
        WebServiceClient.getDataInJSON(serverDeliveryForms, args: jsonArgs)
        WebServiceClient.getDataInJSON(serverJsonLines, args: jsonArgs)
    }
    
    func validateLogin(login: String, password: String) {
        wsClient.pushLoginData(serverLoginAuthPath, login: login, password: password)
    }
    
    func validateDiscount(cl: Client, key: String) {
        wsClient.validateDiscount(serverValidateDiscountPath, cl: cl, key: key)
    }
    
    func dispatchOrder(cl: Client) {
        wsClient.dispatchOrder(serverBuildOrderPath, cl: cl)
    }
    
    func fetchUserData() throws -> (Bool) {
        /* Get user token from secGen */
        let token = try secGen.tokenExpired()

        /* Get user info and adresses from the server */
        wsClient.getUserData(serverGetUserData, token: token.token!)
        
        return true
    }
}
