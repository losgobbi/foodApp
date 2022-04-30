//
//  CheckoutCarViewController.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 11/17/16.
//  Copyright © 2016 Hagen. All rights reserved.
//

import Foundation
import Eureka

class CheckoutCarViewController: FormViewController {
    
    /* Api reference */
    private var api = FoodApp.sharedInstance
    private var orderContainer: Order?
    private var client: Client?
    private var userCar = [Product]()
    
    /* Form */
    private var txtRow: TextRow?
    private var section: Section?
    
    /* General control */
    private var discountValue: Float = 0
    private var discountSum: Float = 0
    private var popup = PopupAlertView()
    
    override func viewDidAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector:#selector(CheckoutCarViewController.discountCompleted(_:)),
            name: FoodAppNotifications.OrderDiscountStatus.rawValue, object: nil)
        
        //FIXME didload uses the anonymous car list to render form.
        //we should use some indication after login finished to flush cl/order.
        do {
            client = try api.getUser()
            userCar = try api.getUserProductCar()
            if let order = try api.getUserOrder() {
                orderContainer = order
            }
        } catch let error as NSError {
            print("CheckoutCarViewController viewDidAppear(): Error = \(error)")
        }
        
        /* reset pay */
        orderContainer!.discountInfo = nil
    }
    
    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let backView = UIView(frame: CGRectMake(0, 0, nvLogoWidth, nvLogoHeight))
        let titleImageView = UIImageView(image: UIImage(named: "logo-foodApp.png"))
        
        titleImageView.frame = CGRectMake(0, nvStatusBarHeight, nvLogoWidth, nvLogoHeight)
        backView.addSubview(titleImageView)
        self.navigationItem.titleView = backView
        self.navigationController?.navigationBar.layoutIfNeeded()
        
        do {
            client = try api.getUser()
            userCar = try api.getUserProductCar()
            if let order = try api.getUserOrder() {
                orderContainer = order
            }
        } catch let error as NSError {
            print("CheckoutCarViewController viewDidLoad(): Error = \(error)")
        }
        
        let (total, subtotal, frete) = calcPrice()
        
        section = Section("Lista de Compras")
        for i in 0..<userCar.count {
            txtRow = TextRow()
            txtRow!.title = "Qtd \(userCar[i].productListCount)"
            txtRow!.baseValue = userCar[i].name
            txtRow!.disabled = true
            section!.append(txtRow!)
        }
        form.append(section!)

        section = Section("Cupom de desconto")
        txtRow = TextRow()
        txtRow!.placeholder = "Insira aqui (opcional)"
        txtRow!.tag = "discount"
        section!.append(txtRow!)
        
        let button = ButtonRow()
        button.tag = "btValidateDiscount"
        button.title = "Validar cupom"
        button.hidden = Condition.Function(["discount"], { form in
            let discountRow = form.rowByTag("discount") as! TextRow
            return (discountRow.cell.textField.text!.isEmpty ? true: false)
        })
        button.onCellSelection(self.validateDiscount)
        button.cellSetup { (cell, row) in
            cell.backgroundColor = UIColorFromHex(buttonBg1)
            cell.tintColor = UIColorFromHex(buttonTintColor1)

        }
        section!.append(button)
        form.append(section!)
        
        section = Section("Total")
        txtRow = TextRow()
        txtRow!.title = "Subtotal"
        let subtotalFmt = String.localizedStringWithFormat("%.2f", subtotal)
        txtRow!.baseValue = "R$ \(subtotalFmt)"
        txtRow!.disabled = true
        txtRow!.tag = "subtotal"
        section!.append(txtRow!)

        txtRow = TextRow()
        txtRow!.title = "Frete"
        let freteFmt = String.localizedStringWithFormat("%.2f", frete)
        txtRow!.baseValue = "R$ \(freteFmt)"
        txtRow!.disabled = true
        txtRow!.tag = "frete"
        section!.append(txtRow!)
        
        txtRow = TextRow()
        txtRow!.title = "Desconto"
        var discountFmt = String.localizedStringWithFormat("%.2f", discountValue)
        txtRow!.baseValue = "R$ \(discountFmt)"
        txtRow!.disabled = true
        txtRow!.hidden = Condition.Function(["discount"], { form in
            let discountRow = form.rowByTag("discount") as! TextRow
            return (discountRow.cell.textField.text!.isEmpty ? true: false)
        })
        txtRow!.tag = "discountValue"
        txtRow!.cellUpdate { (cell, row) in
            discountFmt = String.localizedStringWithFormat("%.2f", self.discountValue)
            row.baseValue = "R$ \(discountFmt)"
        }
        section!.append(txtRow!)

        txtRow = TextRow()
        txtRow!.title = "Total"
        let totalFmt = String.localizedStringWithFormat("%.2f", total)
        txtRow!.baseValue = "R$ \(totalFmt)"
        txtRow!.disabled = true
        txtRow!.tag = "total"
        txtRow!.cellUpdate { (cell, row) in
            var value = total
            if self.discountSum > 0 {
                value = self.discountSum + frete
            }
            let totalFmt = String.localizedStringWithFormat("%.2f", value)
            row.baseValue = "R$ \(totalFmt)"
        }
        section!.append(txtRow!)
        form.append(section!)
    }
    
    func calcPrice() -> (total: Float, subtotal: Float, frete: Float) {
        var carSum : Float = 0
        var subTotal: Float = 0
        var frete: Float = 0
        
        for pd in 0..<userCar.count {
            let pdPrice = userCar[pd].discount ? userCar[pd].discountPrice: userCar[pd].price
            carSum += (pdPrice * Float(userCar[pd].productListCount))
        }
        
        subTotal = carSum
        
        /* update 'frete' */
        if let df = orderContainer!.orderDeliveryForm {
            frete = df.price
            carSum += frete
        }
        
        return (carSum, subTotal, frete)
    }

    /* validate 'Cupom' information */
    func validateDiscount(cell: ButtonCellOf<String>, row: ButtonRow) {
        let formvalues = self.form.values()
        let promoString = formvalues["discount"] as! String
        
        orderContainer!.discountInfo = promoString
        
        api.validateDiscount(client!, key: promoString)
        self.navigationItem.hidesBackButton = true
        self.navigationItem.rightBarButtonItem?.enabled = false
        
        form.rowByTag("btValidateDiscount")?.disabled = true
        form.rowByTag("btValidateDiscount")?.evaluateDisabled()
        form.rowByTag("btValidateDiscount")?.reload()
    }
    
    func discountCompleted(notification: NSNotification) {
        let status = notification.userInfo!["discountStatus"] as! Int
        
        if status != 200 {
            let errMsg = notification.userInfo!["msg"] as! String
            let msg = PopupMessages.OrderDiscountInValid.Message + " (\(errMsg))"
            
            popup.popupAlert(PopupMessages.OrderDiscountInValid.Title,
                message: msg, button: PopupMessages.OrderDiscountInValid.Button, view: self)
            orderContainer!.discountInfo = nil
        } else {
            let discountPrice = notification.userInfo!["discountPrice"] as! Float
            let discSum = notification.userInfo!["discountSum"] as! Float
            
            discountValue = discountPrice
            discountSum = discSum
            
            /* update cells */
            form.rowByTag("discountValue")?.updateCell()
            form.rowByTag("discountValue")?.reload()

            form.rowByTag("total")?.updateCell()
            form.rowByTag("total")?.reload()

            popup.popupAlert(PopupMessages.OrderDiscountValid.Title, message: PopupMessages.OrderDiscountValid.Message, button: PopupMessages.OrderDiscountValid.Button, view: self)
        }

        self.navigationItem.rightBarButtonItem?.enabled = true
        self.navigationItem.hidesBackButton = false
        
        form.rowByTag("btValidateDiscount")?.disabled = false
        form.rowByTag("btValidateDiscount")?.evaluateDisabled()
        form.rowByTag("btValidateDiscount")?.reload()
    }
    
    @IBAction func proceedAction(sender: AnyObject) {
        do {
            let (logged, _, _) = try api.userIsLogged()
            
            if (logged == true) {
                self.performSegueWithIdentifier("CartToOrderNav", sender: self)
            } else {
                self.performSegueWithIdentifier("CartToLogin", sender: self)
            }
        } catch let error as NSError {
            print("ProceedAction(): Is user logged?. Error = \(error)")
        }
    }
}
