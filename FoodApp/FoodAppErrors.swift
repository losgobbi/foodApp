//
//  FoodAppErrors.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 5/31/15.
//  Copyright (c) 2015 Hagen. All rights reserved.
//
//  Custom errors for API
//

import Foundation

/* Array of errors */
var foodAppErrors = [NSError]()

/* Error domain */
let FoodAppErrorDomain = "com.xxx.foodApp.errorDomain"

/* Error codes */
enum Codes: Int, ErrorType {
    /* PersistencyManager */
    case MaxProductAmountReached    = -1
    case ElementNotFound            = -2
    case MetaDataExceeded           = -3
    /* WebServiceClient */
    case DownloadImageFailed        = -101
    case FetchJsonFailed            = -102
    case PushLoginFailed            = -103
    case PushOrderFailed            = -104
    case PushOrderFailedWrongFmt    = -105
    case PushOrderFailedCantSave    = -106
    case FetchUserInfoFailed        = -107
    case PushAddressFailed          = -108
    case PushDiscountFailed         = -109

    /* SecretGen */
    case MaxUserLogged              = -202
    
    /* General */
    case UnableToRestoreSavedData   = -303
    case UnableToSaveData           = -304
}

/* Build NSError to keep compatibility with third parties catch */
func error( message message: String, errorCode: Int) -> NSError {
    
    var msg = message
    
    // Append time
    let now = NSDate()
    let errorTime = NSDateFormatter.localizedStringFromDate(now,
        dateStyle: .ShortStyle, timeStyle: .ShortStyle)
    msg += ", Date: \(errorTime)"
    
    // Build error
    let error = NSError(domain: FoodAppErrorDomain, code: errorCode,
        userInfo: [NSLocalizedDescriptionKey: msg])
    
    // Store error
    appendError(error)
    
    // Always print to keep track
    print("[Food App error] code: '\(error.code)', localized:'\(error.localizedDescription)'\n")
    
    return error
}

func appendError(error: NSError) {
    /* if max, remove the first added */
    if foodAppErrors.count == apiErrorsReportSize {
        foodAppErrors.removeAtIndex(0)
    }
    
    foodAppErrors.append(error)
    saveError()
}

/* We have to save error buffer in order to send with crash report */
func saveError() {
    var errorString = [String]()
    for i in 0..<foodAppErrors.count {
        errorString.append(foodAppErrors[i].description)
    }
    
    // Insert into plist
    let defaults = NSUserDefaults.standardUserDefaults()
    defaults.setObject(errorString, forKey: "FoodAppErrors")
   
    // We must force write
    defaults.synchronize()
}
