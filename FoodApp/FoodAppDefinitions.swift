//
//  FoodAppDefinitions.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 4/3/15.
//  Copyright (c) 2015 Hagen. All rights reserved.
//
//  Only API definitions
//

import UIKit

/* Internal and external notifications */
enum FoodAppNotifications: String {
    /* Data was fetched from the server */
    case FetchData = "com.xxx.deliveryApp.jsonFetchNotification"
    /* Image was downloaded */
    case ImageNotification = "com.xxx.deliveryApp.imageNotification"
    /* Data is ready for usage */
    case DataReady = "com.xxx.deliveryApp.dataReady"
    /* Login status indication */
    case LoginStatus = "com.xxx.deliveryApp.loginStatus"
    /* Validate order indication */
    case OrderDiscountStatus = "com.xxx.deliveryApp.orderDiscount"
    /* Order dispatched indication */
    case OrderDispatched = "com.xxx.deliveryApp.orderDispatched"
    /* User synchronized */
    case UserSynchronized = "com.xxx.deliveryApp.userSynchronized"
    /* Create user status indication */
    case createUserStatus = "com.xxx.deliveryApp.createUserStatus"
    /* Get user info indication */
    case getUserStatus = "com.xxx.deliveryApp.getUserStatus"
}

/*** General constants ***/

/* Uses a internal code line when we can't find the correct one */
let defaultInternalLine = 0

/* Uses a default image (i.e. when we can't download it, or in case of errors) */
let defaultProductImage = "productImageNotFound.png"
let defaultLineImage = "lineImageNotFound.jpg"

/* Line window */
let lineWindowSupport = 0
let lineWindow = 5

/* WS module configuration */
let maxWsImagesRequests = 10
let maxfetchInitialRetries = 10

/*** Backend paths ***/

/* Domain of provider */
let domain = "https://www.foodApp.com.br/"

/* urls for consuming json */
let serverJsonLines = domain + "api/linhas/"
let serverJsonProducts = domain + "api/linha/produtos/"
let serverDeliveryForms = domain + "api/entrega_formas"

/* url for login/create user interaction */
let serverLoginAuthPath = domain + "api/usuario/login"
let serverCreateUserPath = domain + "api/usuario/add"
let serverAddUserAddressPath = domain + "api/usuario/endereco/add"

/* url for order interaction */
let serverValidateDiscountPath = domain + "api/cupom/valida"
let serverBuildOrderPath = domain + "api/pedido/add"
let serverGetUserData = domain + "api/usuario/detail"
