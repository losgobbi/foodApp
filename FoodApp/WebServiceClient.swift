//
//  WebServiceClient.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 4/1/15.
//  Copyright (c) 2015 Hagen. All rights reserved.
//
//  Handle communication with the Mobile Back-End
//

import UIKit
import Alamofire
import SwiftyJSON
import SDWebImage

struct WebServiceJsonArgs {
    //special fields
    var categoria_id: Int = 0
    var linha_id: Int = 0
    
    //general fields
    var page: Int = 0
    var limit: Int = 0
    var order: String = ""
}

func buildParamReq(let jsonArgs: WebServiceJsonArgs) -> [String: AnyObject] {
    var param: [String: AnyObject] = Dictionary()
    
    if jsonArgs.categoria_id > 0 {
        param["categoria_id"] = jsonArgs.categoria_id
    }
    if jsonArgs.linha_id > 0 {
        param["linha_id"] = jsonArgs.linha_id
    }
    if jsonArgs.page != 0 {
        param["page"] = jsonArgs.page
    }
    
    return param
}

class WebServiceClient {

    /* Pointer to the last request */
    private var req: Alamofire.Request?
    
    /* Buffer of images requests */
    private var reqImgs = [Request?](count: maxWsImagesRequests, repeatedValue: nil)
    
    private func extractHttpHeaders(response: NSHTTPURLResponse) ->
        (len: Int32?, type: String?, date: NSDate?) {
            let hf = response.allHeaderFields as! Dictionary<String, String>
            
            /* Content-lenght */
            var len: Int32?
            if let lenField = hf["Content-Length"] {
                len = NSNumberFormatter().numberFromString(lenField)!.intValue
            }
            
            /* Content-type */
            var type: String?
            if let typeField = hf["Content-Type"] {
                type = typeField
            }
            
            /*
             * "Last-Modified" field is formatted like:
             *  "Wed, 05 Dec 2012 12:00:15 GMT"
             */
            var date: NSDate?
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
            /* TODO Should be QA1480 ? */
            dateFormatter.timeZone = NSTimeZone(abbreviation: "GMT")
            
            if let dateField = hf["Last-Modified"] {
                date = dateFormatter.dateFromString(dateField)
            }
            
            return (len, type, date)
    }
    
    private func formatItens(cl: Client) -> String {
        /* build item list */
        var dicItems = [[String: AnyObject]]()
        let pds = cl.clientProductList.allObjects as? [Product]
        for i in 0..<pds!.count {
            let pd = pds![i]
            if let vd = pd.vendor as? Vendor {
                let gridId = vd.getPdGridId()
                let itemEntry = [ "grade_id" : gridId, "quantidade" : Int(pd.productListCount)]
                dicItems.append(itemEntry)
            }
        }
        
        /*
         * format items in the following syntax:
         *   [{"grade_id": id, "quantidade": count}, {"grade_id": id, "quantidade": count}]
         */
        var items = [String]()
        for dicEntry in dicItems {
            /* replace stage 1 */
            var set = [String]()
            let replaceStg1 = ["["]
            set.append(dicEntry.description)
            replace_multiplechars(&set, token_source: replaceStg1, token_dst: "{")
            
            let resStage1 = set.removeFirst()
            
            /* replace stage 2 */
            let replaceStg2 = ["]"]
            set.append(resStage1)
            replace_multiplechars(&set, token_source: replaceStg2, token_dst: "}")
            
            /* final string for the next stage */
            let result = set.removeFirst()
            items.append(result)
        }
        
        /* XXX stage 3: we cant use description output, so build manually */
        var itemsArg = ""
        itemsArg += "["
        for i in 0..<items.count {
            if i != 0 {
                itemsArg += ","
            }
            itemsArg += items[i]
        }
        itemsArg += "]"
        
        return itemsArg
    }

    func pushLoginData(url: String, login: String, password: String) {
        let param: [String: AnyObject] = ["email": login, "password": password]
        req = request(.POST, url, parameters: param)
            .responseJSON { response in
                var notifyInfo: [NSObject : AnyObject]?
                switch response.result {
                case .Success(let data):
                    let loginRsp = JSON(data)

                    extractLoginInformation(loginRsp.dictionary!, notifyInfo: &notifyInfo)
                    break;
                    
                case .Failure(let AlError):
                    error(message: "pushLoginData(): cant push login = '\(login)' password = '\(password.hash)'. Error = '\(AlError)'",
                        errorCode: Codes.PushLoginFailed.rawValue)

                    notifyInfo = ["loginStatusHttp": 400]
                    break;
                }
                
                NSNotificationCenter.defaultCenter().postNotificationName(
                    FoodAppNotifications.LoginStatus.rawValue,
                    object: self, userInfo: notifyInfo)
        }
    }
 
    
    func getUserData(url: String, token: String) {
        let pushData: [String: AnyObject] =
        [ "token": token ]
        req = request(.POST, url, parameters: pushData)
            .responseJSON { response in
                var notifyInfo: [NSObject : AnyObject]?
                switch response.result {
                case .Success(let data):
                    let resp = JSON(data)

                    extractUserInformation(resp.dictionary!, notifyInfo: &notifyInfo)
                    break;
                    
                case .Failure(let AlError):
                    error(message: "getUserData(): failed. Error = '\(AlError)'",
                        errorCode: Codes.PushLoginFailed.rawValue)
                    notifyInfo = ["status": 400]
                    break;
                    
                }
                
                NSNotificationCenter.defaultCenter().postNotificationName(
                    FoodAppNotifications.getUserStatus.rawValue,
                    object: self, userInfo: notifyInfo)
        }
    }
    
    func pushCreateUserData(url: String, user: Client, address: Address) {
        let pushData: [String: AnyObject] =
        [ "usuario_nome": user.fullName,
            "usuario_email": user.email,
            "usuario_senha_nova": user.password,
            "usuario_confirm": user.password,
            "usuario_data_nascimento": user.birthday,
            "usuario_cpf": user.cpf,
            "usuario_telefone": user.cellPhone,
            "usuario_celular": user.cellPhone,
            "usuario_newsletter": "0",
            "endereco_cobranca_cep": address.zipcode!,
            "endereco_cobranca_endereco": address.address!,
            "endereco_cobranca_numero": address.number!,
            "endereco_cobranca_complemento": address.complement!,
            "endereco_cobranca_bairro": address.neighborhood!,
            "endereco_cobranca_cidade": address.city!,
            "endereco_cobranca_uf": address.state! ]

        req = request(.POST, url, parameters: pushData)
            .responseJSON { response in
                var notifyInfo: [NSObject : AnyObject]?
                switch response.result {
                case .Success(let data):
                    let resp = JSON(data)
                    extractUserInformation(resp.dictionary!, notifyInfo: &notifyInfo)
                case .Failure(let AlError):
                    error(message: "pushCreateUserData(): failed. Error = '\(AlError)'",
                        errorCode: Codes.PushLoginFailed.rawValue)
                    notifyInfo = ["status": 400]
                }
                NSNotificationCenter.defaultCenter().postNotificationName(
                    FoodAppNotifications.getUserStatus.rawValue,
                    object: self, userInfo: notifyInfo)
        }
    }
    
    func pushAddUserAddress(url: String, user: Client, address: Address) {
        let pushData: [String: AnyObject] =
        [ "token": user.login,
            "endereco_cep":  address.zipcode!,
            "endereco_endereco": address.address! ,
            "endereco_numero": address.number! ,
            "endereco_complemento": String(address.complement),
            "endereco_bairro": address.neighborhood! ,
            "endereco_cidade": address.city! ,
            "endereco_uf": address.state! ,
            "endereco_cobranca": "1" ]
        req = request(.POST, url, parameters: pushData)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .Success(let data):
                    let json = JSON(data)
                    let code = json["code"].intValue
                    NSNotificationCenter.defaultCenter().postNotificationName(
                        FoodAppNotifications.createUserStatus.rawValue,
                        object: self, userInfo: ["createUserStatus": code])
                    break;
                case .Failure(let AlError):
                    NSNotificationCenter.defaultCenter().postNotificationName(
                        FoodAppNotifications.createUserStatus.rawValue,
                        object: self, userInfo: ["createUserStatus": 1])
                    error(message: "pushCreateUserData(): cant push login = '\(user.fullName)' address = '\(address.address)'. Error = '\(AlError)'",
                        errorCode: Codes.PushAddressFailed.rawValue)
                }
        }
    }
    
    /* Keep static for external usage */
    static func getDataInJSON(url: String, args: WebServiceJsonArgs) {
        let param = buildParamReq(args)
            request(.POST, url, parameters: param)
            .validate()
            .responseJSON { response in
                var notifyInfo: [NSObject : AnyObject]?
                switch response.result {
                case .Success(let fetchResult):
                    notifyInfo = ["jsonRaw": fetchResult, "jsonUrl": url, "jsonArgs": param]
                case .Failure(let AlError):
                    let apiErr = error(message: "getDataInJSON(): Cant get json data Url = \(url) param = \(param). Error = '\(AlError)'", errorCode: Codes.FetchJsonFailed.rawValue)
                    notifyInfo = ["jsonError": apiErr]
                }
                NSNotificationCenter.defaultCenter().postNotificationName(
                    FoodAppNotifications.FetchData.rawValue,
                    object: self, userInfo: notifyInfo)
        }
    }
    
    func getProductImage(pd: Product, imgView: UIImageView) {
        let pdImg = pd.productImage
        let url = domain + pdImg.path
        
        imgView.image = nil
        imgView.sd_cancelCurrentImageLoad()

        /* XXX there is another way? ProductView progress vs SD progress */
//        if isIpad() {
//            imgView.setShowActivityIndicatorView(true)
//        }
        
        imgView.sd_setImageWithURL(NSURL(string: url)) {
            (img, sdError, cacheTp, url) -> Void in
            if let sError = sdError {
                error(message: "getProductImage(): cant get image Url = \(url) PdCode:'\(pd.id)' PdPath = '\(pdImg.path)' sdError = \(sError)",
                    errorCode: Codes.DownloadImageFailed.rawValue)
                
                /*
                * We need to avoid the 'loading' bar loop. If we got some
                * error here, we need to stop 'loading' and show something.
                * We will not fill the pdImg. That means, if the user go
                * forward and back (scroll), we will give another shot (retry)
                */
                let transientImage = UIImage(named: defaultProductImage)
                imgView.image = transientImage
                return
            }
            
            /* do not fill pdImg.image because de image will be at SDCache */
            
            //TODO Extract http headers
        }
    }
    
    func getFilterLineImage(image: Image, imgView: UIImageView) {
        let url = domain + image.path
        req = request(.GET, url)
            .validate()
            .validate(contentType: ["image/bmp", "image/gif", "image/png", "image/jpeg"])
            .response{ (request, response, data, AlError) in
                
                if let aErr = AlError {
                    error(message: "getFilterLineImage(): cant get image Url = \(url) Path = '\(image.path)' AlError = \(aErr)",
                        errorCode: Codes.DownloadImageFailed.rawValue)
                    
                    let transientImage = UIImage(named: defaultProductImage)
                    imgView.image = transientImage
                    return
                }
                
                /* Extract http headers */
                let (len, type, date) = self.extractHttpHeaders(response!)
                image.sizeBytes = len ?? 0
                image.format = type ?? "unknown"
                if let dateValue = date {
                    image.uploadedDate = dateValue.timeIntervalSinceReferenceDate
                }
                
                /* Build image */
                let binData = data!
                imgView.image = UIImage(data: binData)
                image.image = binData
        }
    }

    func validateDiscount(url: String, cl: Client, key: String) {
        //key will be inserted at url, so remove chars
        var keyFmt = key
        removeURLForbiddenChars(&keyFmt)
        
        let urlFmt = url + "/" + keyFmt
        let itemsArg = formatItens(cl)
        let pushData: [String: AnyObject] =
            [ "itens": itemsArg]
        req = request(.POST, urlFmt, parameters: pushData)
            .responseJSON { response in
                var notifyInfo: [NSObject : AnyObject]?
                switch response.result {
                case .Success(let data):
                    let discountRsp = JSON(data)
                    // parse json body
                    extractDiscountInformation(discountRsp.dictionary!, notifyInfo: &notifyInfo)
                case .Failure(let AlError):
                    error(message: "validateDiscount(): failed. Error = '\(AlError)'",
                        errorCode: Codes.PushDiscountFailed.rawValue)
                    // use invalid request
                    notifyInfo = ["discountStatus": 400, "msg": "\(Codes.PushDiscountFailed.rawValue)"]
                }
                NSNotificationCenter.defaultCenter().postNotificationName(
                    FoodAppNotifications.OrderDiscountStatus.rawValue,
                    object: self, userInfo: notifyInfo)
            }
    }
    
    func dispatchOrder(url: String, cl: Client) {
        let itemsArg = formatItens(cl)
        
        /* format some fields */
        let date = NSDate(timeIntervalSinceReferenceDate: cl.clientOrder.date)
        let dateTxt = formatDate2string(date, format: "dd/MM/yyyy")
        let time = NSDate(timeIntervalSinceReferenceDate: cl.clientOrder.time)
        let timeTxt = formatDate2string(time, format: "HH:mm")
        
        /* insert pay token */
        var info: String = ""
        if let addInfo = cl.clientOrder.addInfo {
            info += addInfo
        }
        if let payOpt = cl.clientOrder.pay {
            info += " <PAGAMENTO> " + payOpt
        }
        
        let pushData: [String: AnyObject] =
        [ "itens": itemsArg,
            "usuario_id":  Int(cl.id),
            "usuario_endereco_id": Int(cl.clientOrder.deliveryAddressId),
            "entrega_forma_id": Int(cl.clientOrder.orderDeliveryForm!.id),
            "entrega_data": dateTxt,
            "entrega_hora": timeTxt,
            "entrega_observacao": info,
            "cupom": cl.clientOrder.discountInfo ?? ""]
        
        req = request(.POST, url, parameters: pushData)
            .responseJSON { response in
                var notifyInfo: [NSObject : AnyObject]?
                switch response.result {
                case .Success(let data):
                    let orderRsp = JSON(data)
                    // parse json body
                    extractOrderInformation(orderRsp.dictionary!, notifyInfo: &notifyInfo)
                case .Failure(let AlError):
                    error(message: "dispatchOrder(): failed. Error = '\(AlError)'",
                        errorCode: Codes.PushOrderFailed.rawValue)
                    // use invalid request
                    notifyInfo = ["orderStatus": 400, "msg": "\(Codes.PushOrderFailed.rawValue)"]
                }
                NSNotificationCenter.defaultCenter().postNotificationName(
                    FoodAppNotifications.OrderDispatched.rawValue,
                    object: self, userInfo: notifyInfo)
            }
    }
    
    private func cancelImgReq(pd: Product, imgView: UIImageView) {
        //TODO unsupported now
        if !isIpad() {
            print("cancelImgReq(): unsupported on ScrollView (Iphone)")
            return
        }
        
        if let validReq = reqImgs[imgView.tag] {
            validReq.cancel()
            reqImgs[imgView.tag] = nil
            print("getProductImage(): Request tag=\(imgView.tag), id=\(pd.id) was cancelled")
        }
    }
}