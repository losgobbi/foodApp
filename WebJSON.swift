//
//  WebJSON.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 2/1/16.
//  Copyright © 2016 Hagen. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

func sanitizeJsonUrls(inout url: String) {
    removeURLForbiddenChars(&url)
}

func sanitizeJsonText(inout txt: String) {
    /* Remove 1 or more <...> pattern (not <>) */
    let str = txt.stringByReplacingOccurrencesOfString("<[^>]+>", withString: "",
        options: .RegularExpressionSearch, range: nil)

    txt = str
}

func sanitizeJsonProduct(moc: NSManagedObjectContext) {
    let pds = try! Product.getAll(moc)!
    
    for i in 0..<pds.count {
        let pd = pds[i]
        /* fix discount flag */
        if (pd.discount && (pd.discountPrice > pd.price || pd.discountPrice <= 0)) {
            print("sanitizeProduct(): removing discount flag from pd:\(pd.name) id:\(pd.id)")
            pd.discount = false
        }
    }
}

func parseMetaData(moc: NSManagedObjectContext, arrayEntry: [String:JSON]) {
    let count = arrayEntry["count"]!.int32Value
    let current = arrayEntry["current"]!.int32Value
    let nextPage = arrayEntry["nextPage"]!.boolValue
    let page = arrayEntry["page"]!.int32Value
    let pageCount = arrayEntry["pageCount"]!.int32Value
    
    let info = MetaData.add(moc)
    info.count = count
    info.current = current
    info.nextPage = nextPage
    info.page = page
    info.pageCount = pageCount
}

func extractProducts(moc: NSManagedObjectContext, arrayEntry: [String:JSON],
    reqArgs: [String: AnyObject]) throws {
    
    /* parse meta information */
    parseMetaData(moc, arrayEntry: arrayEntry)
    
    /* cant exceed, so ignore exception */
    let metaInfo = try! MetaData.get(moc)!
    print(metaInfo)
    
    var jsonArgs = WebServiceJsonArgs()

    /* check if its empty */
    if metaInfo.pageCount <= 0 {
        let id = reqArgs["linha_id"] as! Int
        
        /* force sync */
        let line = try! Line.get(moc, lineCode: Int32(id))
        line!.syncedProducts = true
        print("Synced 0 products for line = \(line!.name)")
        
        let lineOutOfSync = try? Line.getOutOfSync(moc)
        if let los = lineOutOfSync {
            print("Syncing line = \(los.name)")
            jsonArgs.linha_id = Int(los.id)
            WebServiceClient.getDataInJSON(serverJsonProducts, args: jsonArgs)
        }

        MetaData.rem(moc, metaInfo: metaInfo)
        return
    }
    
    let arrayData = arrayEntry["data"]!
    for dicEntry in arrayData.arrayValue {
        let line = dicEntry["Linha"]
        let idLine = line["id"].intValue

        let grid = dicEntry["Grade"]
        let promoStatus = grid["preco_promocao_status"].boolValue
        let price = grid["preco"].floatValue
        let pricePromo = grid["preco_promocao"].floatValue
        let gridId = grid["id"].intValue
        
        let pd = dicEntry["Produto"]
        let pdId = pd["id"].intValue
        let thumb = pd["thumb"].stringValue
        let thumb_path = pd["thumb_path"].stringValue
        let thumb_dir = pd["thumb_dir"].stringValue
        var imgPath = "/" + thumb_path + "/" + thumb_dir + "/" + "610x330-" + thumb
        let status = pd["status"].int16Value
        var desc = pd["descricao_resumida"].stringValue
        let name = pd["nome"].stringValue
        
        /* XXX remove some weird code from ws */
        sanitizeJsonUrls(&imgPath)
        
        /* Remove special characters */
        sanitizeJsonText(&desc)
        
        let pdImg: Image?
        pdImg = Image.createImage(moc)
        pdImg!.path = imgPath
        pdImg!.local = false

        /* create product */
        let pdObj = Product.add(moc)
        pdObj.id = Int32(pdId)
        pdObj.name = name
        pdObj.desc = desc
        pdObj.price = price
        pdObj.discountPrice = pricePromo
        pdObj.discount = promoStatus
        pdObj.status = status
        
        /* attach a image to it */
        pdObj.productImage = pdImg!

        /* save line to ws args */
        jsonArgs.linha_id = idLine

        /* add product to line */
        let pdLine = try Line.get(moc, lineCode: Int32(idLine))
        if let line = pdLine {
            Line.addProduct(moc, line: line, pd: pdObj)
        } else {
            /* can't find the correct one. use a internal */
            let dflLine = try Line.get(moc, lineCode: Int32(defaultInternalLine))
            Line.addProduct(moc, line: dflLine!, pd: pdObj)
        }
        
        /* vendor specific */
        let vendorInfo = Vendor()
        vendorInfo.setPdGridId(gridId)
        pdObj.vendor = vendorInfo
    }
    
    /* there are more pages? */
    if metaInfo.page != metaInfo.pageCount {
        jsonArgs.page = Int(metaInfo.page) + 1
        WebServiceClient.getDataInJSON(serverJsonProducts, args: jsonArgs)
    } else {
        /* we synced all products for a line. Starts again for another one */
        let pdLine = try Line.get(moc, lineCode: Int32(jsonArgs.linha_id))
        if let line = pdLine {
            print("Synced all products for line = \(line.name)")
            line.syncedProducts = true
            
            let lineOutOfSync = try? Line.getOutOfSync(moc)
            if let los = lineOutOfSync {
                print("Syncing line = \(los.name)")
                jsonArgs.linha_id = Int(los.id)
                WebServiceClient.getDataInJSON(serverJsonProducts, args: jsonArgs)
            }
        }
    }
    
    /* remove meta */
    MetaData.rem(moc, metaInfo: metaInfo)
}

func extractLines(moc: NSManagedObjectContext, arrayEntry: [String:JSON]) {
    
    /* parse meta information */
    parseMetaData(moc, arrayEntry: arrayEntry)
    
    /* cant exceed, so ignore exception */
    let metaInfo = try! MetaData.get(moc)!
    print(metaInfo)

    let arrayData = arrayEntry["data"]!
    for dicEntry in arrayData.arrayValue {
        let entry = dicEntry["Linha"]
        let idLine = entry["id"].intValue
        let titleLine = entry["nome"].stringValue
        var descLine = entry["descricao"].stringValue
        let createdDate = entry["created"].stringValue
        let modifiedDate = entry["modified"].stringValue
        let thumb_file = entry["thumb_file"].stringValue
        let thumb_path = entry["thumb_path"].stringValue
        let thumb_dir = entry["thumb_dir"].stringValue
        let status = entry["status"].int16Value
        var imgPath = "/" + thumb_path + "/" + thumb_dir + "/" + thumb_file
        
        /* maybe this line is already SYN */
        if let lineExist = try? Line.get(moc, lineCode: Int32(idLine)) {
            print("Line '\(lineExist!.name)' SYN:'\(lineExist!.syncedProducts)' already exists")
            continue
        }

        /* XXX remove some weird code from ws */
        sanitizeJsonUrls(&imgPath)
        
        /* Remove special characters */
        sanitizeJsonText(&descLine)

        /* build local image, the name is the 'nome' field */
        let lineImg: Image?
        if thumb_path.isEmpty || thumb_dir.isEmpty || thumb_file.isEmpty {
            lineImg = Image.createImage(moc)
            lineImg!.local = true
            lineImg!.path = titleLine + "Line"
            lineImg!.stringIdentifier = titleLine + "Line"
        } else {
            lineImg = Image.createImage(moc)
            lineImg!.path = imgPath
            lineImg!.local = false
            lineImg!.stringIdentifier = titleLine + "Line"
        }
        
        let lineProductImg: Image?
        lineProductImg = Image.createImage(moc)
        lineProductImg!.local = true
        lineProductImg!.path = titleLine + "Product"
        lineProductImg!.stringIdentifier = titleLine + "Product"
        
        let lineObj = Line.add(moc)
        lineObj.id = Int32(idLine)
        lineObj.name = titleLine
        lineObj.desc = descLine
        lineObj.status = status

        /* format for dates */
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") /* QA1480 */
        
        /* try to convert the dates */
        if let createDt = dateFormatter.dateFromString(createdDate),
            let modifiedDt = dateFormatter.dateFromString(modifiedDate) {
                let lineCache = Cache.add(moc)
                lineCache.created = createDt.timeIntervalSinceReferenceDate
                lineCache.modified = modifiedDt.timeIntervalSinceReferenceDate
                lineObj.lineCache = lineCache
        }

        /* attach a image to it */
        Line.addImage(moc, line: lineObj, pd: lineImg!)
        Line.addImage(moc, line: lineObj, pd: lineProductImg!)
        
        /* build specific information */
        PersistencyManager.buildLineSpecific(lineObj)
    }
    
    /* there are more pages? */
    if metaInfo.page != metaInfo.pageCount {
        print("There are still lines to fetch, incrementing page")
        //TODO cant test with the current api
    } else {
        /* starts fetching products for a random line */
        let lineOutOfSync = try? Line.getOutOfSync(moc)
        if let line = lineOutOfSync {
            var jsonArgs = WebServiceJsonArgs()
            jsonArgs.linha_id = Int(line.id)
            WebServiceClient.getDataInJSON(serverJsonProducts, args: jsonArgs)
        }
    }
    
    /* remove meta */
    MetaData.rem(moc, metaInfo: metaInfo)
}

func extractLoginInformation(arrayEntry: [String:JSON], inout notifyInfo: [NSObject : AnyObject]?) {

    let code = arrayEntry["code"]!.intValue
    let arrayData = arrayEntry["data"]!
    let token = arrayData["token"].stringValue
    let tokenExpiration = arrayData["token_expiration"].stringValue
    
    /* build notify info */
    notifyInfo = ["loginStatusHttp": code, "token": token, "tokenExpiration": tokenExpiration]
}

func extractNewUserInformation(arrayEntry: [String:JSON], inout notifyInfo: [NSObject : AnyObject]?) {
    
    let code = arrayEntry["code"]!.intValue
    let arrayData = arrayEntry["data"]!
    let user = arrayData["Usuario"]
    
    let id = user["id"].intValue
    let name = user["nome"].stringValue
    let email = user["email"].stringValue
    let cpf = user["cpf"].intValue
    let phone = user["telefone"].stringValue
    let cellphone = user["celular"].stringValue
    let token_expiration = user["token_expiration"].stringValue
    let token = user["token"].stringValue
    let addresses = arrayData["UsuarioEndereco"]
    
    notifyInfo = [
        "status": code,
        "token": token,
        "token_expiration": token_expiration,
        "id": id,
        "name": name,
        "email": email,
        "cpf": cpf,
        "phone": phone,
        "cellphone": cellphone,
        "addresses": addresses.arrayObject!,
    ]
}

func extractUserInformation(arrayEntry: [String:JSON], inout notifyInfo: [NSObject : AnyObject]?) {
    
    let code = arrayEntry["code"]!.intValue
    let arrayData = arrayEntry["data"]!
    
    if (code != 200) {
        /* TODO extract the indicated wrongly sent fields so the newUserVC can show it */
        print("extracting info failed with code \(code) ")
        notifyInfo = [ "status": code ]
        return;
    }
    
    let user = arrayData["Usuario"]
    let addresses = arrayData["UsuarioEndereco"]
    
    /* build notify info */
    notifyInfo = [
        "status": code,
        "user": user.object,
        "addresses": addresses.arrayObject!,
    ]
}

func remReportedLine(inout lines: [Line], targetLine: Int32) {
    for i in 0..<lines.count {
        if lines[i].id != targetLine {
            continue
        }
        
        print("remReportedLine(): removing line = \(lines[i].name) since it was reported")
        lines.removeAtIndex(i)
        return
    }
}

/* Remove lines which cache was expired */
func validateLineCache(moc: NSManagedObjectContext, arrayEntry: [String:JSON]) {
    var unreportedLines = try! Line.getAll(moc)
    let arrayData = arrayEntry["data"]!
    for dicEntry in arrayData.arrayValue {
        let entry = dicEntry["Linha"]
        let idLine = entry["id"].intValue
        let createdDate = entry["created"].stringValue
        let modifiedDate = entry["modified"].stringValue

        do {
            let lineObj = try Line.get(moc, lineCode: Int32(idLine))
            
            /* id was reported, so we have to keep it */
            remReportedLine(&unreportedLines!, targetLine: Int32(idLine))
            
            /* format for dates */
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") /* QA1480 */

            /* try to convert the dates */
            if let currentCreatedDt = dateFormatter.dateFromString(createdDate),
                let currentModifiedDt = dateFormatter.dateFromString(modifiedDate) {
                    var fmt1: String = ""
                    var fmt2: String = ""
                    
                    fmt1 = formatDate2string(currentCreatedDt, format: "dd/MM/YYYY")
                    fmt2 = formatTime2string(currentCreatedDt, format: "HH:mm:ss")
                    print("validateLineCache(): Line '\(lineObj!.name)' CurrentCreated = \(fmt1), \(fmt2)")

                    fmt1 = formatDate2string(currentModifiedDt, format: "dd/MM/YYYY")
                    fmt2 = formatTime2string(currentModifiedDt, format: "HH:mm:ss")
                    print("validateLineCache(): Line '\(lineObj!.name)' CurrentModified = \(fmt1), \(fmt2)")

                    let oldCache = lineObj!.lineCache
                    var cacheTime = NSDate(timeIntervalSinceReferenceDate: oldCache.created)

                    fmt1 = formatDate2string(cacheTime, format: "dd/MM/YYYY")
                    fmt2 = formatTime2string(cacheTime, format: "HH:mm:ss")
                    print("validateLineCache(): Line '\(lineObj!.name)' CacheCreated = \(fmt1), \(fmt2)")
                    
                    cacheTime = NSDate(timeIntervalSinceReferenceDate: oldCache.modified)
                    fmt1 = formatDate2string(cacheTime, format: "dd/MM/YYYY")
                    fmt2 = formatTime2string(cacheTime, format: "HH:mm:ss")
                    print("validateLineCache(): Line '\(lineObj!.name)' CacheModified = \(fmt1), \(fmt2)")

                    /* Created/modified is higher than old cache */
                    if currentCreatedDt.timeIntervalSinceReferenceDate > oldCache.created ||
                        currentModifiedDt.timeIntervalSinceReferenceDate > oldCache.modified {
                            
                            /* Remove line cache and fetch again */
                            print("validateLineCache(): Line '\(lineObj!.name)' SYN:'\(lineObj!.syncedProducts)' is invalid, fetch again...")
                            Line.rem(moc, line: lineObj!)
                    } else {
                        print("validateLineCache(): Line '\(lineObj!.name)' SYN:'\(lineObj!.syncedProducts)' cache is still valid")
                    }
            }
        } catch _ as NSError {
            print("validateLineCache(): Line '\(idLine)' is not ready, cant check cache")
        }
    }
    
    for i in 0..<unreportedLines!.count {
        print("validateLineCache(): removing unreportedline = \(unreportedLines![i].name)")
        Line.rem(moc, line: unreportedLines![i])
    }
}

func extractDeliveryForms(moc: NSManagedObjectContext, arrayEntry: [String:JSON]) {
    let arrayData = arrayEntry["data"]!
    for dicEntry in arrayData.arrayValue {
        let entry = dicEntry["EntregaForma"]
        
        let id = entry["id"].intValue
        let name = entry["nome"].stringValue
        let desc = entry["descricao"].stringValue
        let type = entry["tipo"].stringValue
        let status = entry["status"].int16Value
        let price = entry["preco"].floatValue
        
        /* maybe this form was already inserted */
        if let _ = try? DeliveryForm.get(moc, formId: Int32(id)) {
            continue
        }
        
        let form = DeliveryForm.add(moc)
        form.id = Int32(id)
        form.name = name
        form.desc = desc
        form.type = type
        form.status = status
        form.price = price
    }
}

func extractOrderInformation(arrayEntry: [String:JSON], inout notifyInfo: [NSObject : AnyObject]?) {
    let code = arrayEntry["code"]!.intValue
    
    /* data contains specific error message (i.e. wrong date fmt, wrong xxx fmt) */
    let arrayData = arrayEntry["data"]!
    var msg = ""
    if arrayData.count > 0 {
        msg = "\(Codes.PushOrderFailedWrongFmt.rawValue)"
    }
    
    /* build notify info */
    notifyInfo = ["orderStatus": code, "msg": msg]
}

func extractDiscountInformation(arrayEntry: [String:JSON], inout notifyInfo: [NSObject : AnyObject]?) {
    let code = arrayEntry["code"]!.intValue
    let arrayData = arrayEntry["data"]!["Cupom"]
    
    var msg = arrayEntry["message"]!.stringValue
    let discountPrice = arrayData["desconto"].floatValue
    let discountSum = arrayData["total_com_desconto"].floatValue
    
    if msg.isEmpty {
        msg = "Tente mais tarde"
    }
    
    /* build notify info */
    notifyInfo = ["discountStatus": code, "discountPrice": discountPrice,
                  "discountSum": discountSum, "msg": msg]
}
