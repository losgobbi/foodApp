//
//  AppConfig.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 10/28/15.
//  Copyright © 2015 Hagen. All rights reserved.
//
//  App config file
//

import UIKit

/* Controllers notifications */
enum CtrNotifications: String {
    case BkTableContentChanged = "BookMarksTableContentChanged"
    case CarTableContentChanged = "CarTableContentChanged"
}

/* Popup Alert preset messages */
struct PopupMessages {
    /* No internet conection */
    static let NoInternet = (Title: "Atenção", Message: "Nenhuma conexão com a internet detectada. Ative seus dados ou conecte-se a uma rede Wi-Fi.", Button: "Ok")
    /* Order messages */
    static let OrderValid = (Title: "Atenção", Message: "Pedido enviado com sucesso!", Button: "Ok")
    static let OrderDiscountValid = (Title: "Atenção", Message: "Desconto foi validado!", Button: "Ok")
    static let OrderDiscountInValid = (Title: "Atenção", Message: "Não foi possível validar o cupom!", Button: "Ok")
    static let OrderInvalidTimeWindow = (Title: "Atenção", Message: "Você acabou de realizar o pedido. Aguarde 2 horas para efetuar um novo.", Button: "Ok")
    static let OrderInvalidTime = (Title: "Atenção", Message: "Você só pode efetuar pedidos até as 16:00pm para o dia selecionado.", Button: "Ok")
    static let OrderInvalid = (Title: "Atenção", Message: "Pedido não pode ser enviado!", Button: "Ok")
    static let FillDeliveryForm = (Title: "Atenção", Message: "Escolha a forma de entrega!", Button: "Ok")
    static let UserCreateFailed = (Title: "Atenção", Message: "A criação do usuário falhou. Verifique os dados informados.", Button: "Ok")
    /* Other messages */
    static let CantAddProduct = (Title: "Atenção", Message: "Não é possível adicionar mais que '\(maxProductAmount)' unidades do mesmo produto!", Button: "Ok")
}

/*** General constants ***/

/*
* Define the number of elements in the scrollview on the app's launch.
* Be careful when changing this value, this number works with recycle algorithm.
*/
let scrollInitialNumber = 10
let collectionVisibleCellNumber = 6

/* ViewControllers Indexes */
let viewControllerIndex = 0
let carControllerIndex = 1
let bookMarksControllerIndex = 2
let filterControllerIndex = 3
let aboutControllerIndex = 4

/* Max product amount */
let maxProductAmount = 100

/*** Recycle stuff ***/

/* how many pages will be recycled (best-effort) */
let recycleNumber = 3

/* Default user for the system */
let defaultUser = "anonymous"

/* How many api-errors will be stored in crash report */
let apiErrorsReportSize = 10

/* Definitions for navigation bar style */
let nvStatusBarHeight = CGFloat(13.0)
let nvLogoWidth = CGFloat(138.0)
let nvLogoHeight = CGFloat(70.0)

/* colors */
let buttonBg1 = 0xCD6906
let buttonTintColor1 = 0xEEECE5

/*** Functions ***/

func appVersion() -> String {
    let bundle = NSBundle.mainBundle()
    let mkversion = bundle.infoDictionary!["CFBundleShortVersionString"] as! String
    let bversion = bundle.infoDictionary!["CFBundleVersion"] as! String
    
    return mkversion + " (\(bversion))"
}
