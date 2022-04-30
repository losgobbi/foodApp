//
//  SecretGen.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 12/7/15.
//  Copyright © 2015 Hagen. All rights reserved.
//

import UIKit
import KeychainAccess

class SecretGen {

    private let cpfService = "FoodApp Account Information"
    private let passwordsService = "br.com.foodApp"
    
    func createPasswdToken(login: String, userToken: String, expireDate: String) throws {
        let keychain = Keychain(server: passwordsService, protocolType: .HTTPS)
        
        // set user token
        try keychain
            .label("foodAppLoginToken")
            .comment("FoodApp User Password Information")
            .set(userToken, key: login)
        
        // set expiration date
        try keychain
            .label("foodAppLoginTokenDate")
            .set(expireDate, key: login + userToken)
    }
    
    func tokenExpired() throws -> (expired: Bool, login: String?, token: String?) {
        let keychain = Keychain(server: passwordsService, protocolType: .HTTPS)
        let allKeys = keychain.allKeys()
        
        if allKeys.count == 0 {
            return (true, nil, nil)
        }
        
        // get all itens, we need account
        let data = try keychain.get(allKeys[0]) { $0 }
        
        if data?.label == "foodAppLoginToken" &&
            data?.comment == "FoodApp User Password Information" {
                let accnt = data?.account!
                let userToken = try keychain.get(accnt!)
                let expireDate = try keychain.get(accnt! + userToken!)

                // formatter
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                dateFormatter.timeZone = NSTimeZone(abbreviation: "GMT")
                
                // check expiration date vs current date
                let now = NSDate()
                
                var expired: Bool = false
                if let expiredDate = dateFormatter.dateFromString(expireDate!) {
                    // if expiredDate is higher than now
                    if expiredDate.compare(now) == NSComparisonResult.OrderedAscending {
                        expired = true
                    } else {
                        expired = false
                    }
                }
                
                return (expired, accnt!, userToken)
        } else {
            /* not found, login expired */
            return (true, nil, nil)
        }
    }

    func addClientCPF(login: String, cpfHash: String) throws {
        let keychain = Keychain(service: cpfService)
        try keychain
            .label("foodAppLoginCpf")
            .comment("FoodApp User CPF Information")
            .set(cpfHash, key: login)
    }
    
    func erasePasswords() throws {
        let keychain = Keychain(server: passwordsService, protocolType: .HTTPS)
        try keychain.removeAll()
    }
}
