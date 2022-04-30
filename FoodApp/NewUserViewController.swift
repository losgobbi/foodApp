//
//  NewUserViewController.swift
//  FoodApp
//
//  Created by Lucas Tomazi on 2/13/16.
//  Copyright © 2016 Hagen. All rights reserved.
//

import Foundation
import Eureka
import CoreData

class NewUserViewController : FormViewController {
    
    /* Api reference */
    private var api = FoodApp.sharedInstance
    private var newUser: Client?
    private var newAddress: Address?
    private var newDeliveryAddress: Address?
    
    private var popup = PopupAlertView()

    override func viewWillAppear(animated: Bool) {
        /* notifications for this viewcontroller */
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector:#selector(NewUserViewController.newUserSynched(_:)), name: FoodAppNotifications.UserSynchronized.rawValue, object: nil)
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
        
        /* Default actions for row types */
        NameFloatLabelRow.defaultOnCellHighlight = { cell, row in self.animatedCellAlert(row.baseCell)  }
        EmailFloatLabelRow.defaultOnCellHighlight = { cell, row in self.animatedCellAlert(row.baseCell) }
        PasswordFloatLabelRow.defaultOnCellHighlight = { cell, row in self.animatedCellAlert(row.baseCell) }
        IntFloatLabelRow.defaultOnCellHighlight = { cell, row in self.animatedCellAlert(row.baseCell) }
        DateRow.defaultOnCellHighlight = { cell, row in self.animatedCellAlert(row.baseCell) }
        TextFloatLabelRow.defaultOnCellHighlight = { cell, row in self.animatedCellAlert(row.baseCell) }
        ZipCodeRow.defaultOnCellHighlight = { cell, row in self.animatedCellAlert(row.baseCell) }
        PhoneFloatLabelRow.defaultOnCellHighlight = { cell, row in self.animatedCellAlert(row.baseCell) }
        
        form
            +++ Section("Dados pessoais")
            <<< NameFloatLabelRow() {
                $0.title = "Nome"
                $0.tag = "name"
                }.onChange { row in self.defaultOnChangeCells(row) }
            <<< EmailFloatLabelRow() {
                $0.tag = "email"
                $0.title = "Email"
            }.onChange { row in self.defaultOnChangeCells(row) }
            <<< PasswordFloatLabelRow() {
                $0.tag = "password"
                $0.title = "Senha"
            }.onChange { row in self.defaultOnChangeCells(row) }
            <<< PasswordFloatLabelRow() {
                $0.tag = "reenterpassword"
                $0.title = "Repetir Senha"
            }.onChange { row in self.defaultOnChangeCells(row) }
            <<< PhoneFloatLabelRow() {
                $0.tag = "cpf"
                $0.title = "CPF"
            }.onChange { row in self.defaultOnChangeCells(row) }
            <<< DateRow() {
                $0.tag = "birthdate"
                $0.title = "Data de Nascimento"
            }.onChange { row in self.defaultOnChangeCells(row) }
            <<< PhoneFloatLabelRow() {
                $0.tag = "phone"
                $0.title = "Telefone"
            }.onChange { row in self.defaultOnChangeCells(row) }
            <<< PhoneFloatLabelRow() {
                $0.tag = "cellphone"
                $0.title = "Celular"
            }.onChange { row in self.defaultOnChangeCells(row) }
            +++ Section("Endereço residencial")
            <<< IntFloatLabelRow() {
                $0.tag = "cep"
                $0.title = "CEP"
                let formatter = NSNumberFormatter()
                formatter.maximumIntegerDigits = 8
                $0.formatter = formatter
            }.onChange { row in self.defaultOnChangeCells(row) }
            <<< TextFloatLabelRow() {
                $0.tag = "address"
                $0.title = "Endereço"
            }.onChange { row in self.defaultOnChangeCells(row) }
            <<< IntFloatLabelRow() {
                $0.tag = "number"
                $0.title = "Número"
            }.onChange { row in self.defaultOnChangeCells(row) }
            <<< TextFloatLabelRow() {
                $0.tag = "complement"
                $0.title = "Complemento"
                $0.value = ""
            }.onChange { row in self.defaultOnChangeCells(row) }
            <<< TextFloatLabelRow() {
                $0.tag = "neighborhood"
                $0.title = "Bairro"
            }.onChange { row in self.defaultOnChangeCells(row) }
            <<< TextFloatLabelRow() {
                $0.tag = "city"
                $0.title = "Cidade"
                $0.value = "Porto Alegre"
                $0.disabled = true
            }.onChange { row in self.defaultOnChangeCells(row) }
            <<< TextFloatLabelRow() {
                $0.tag = "uf"
                $0.title = "Estado"
                $0.value = "RS"
                $0.disabled = true
            }.onChange { row in self.defaultOnChangeCells(row) }
            +++ Section("Endereço para entrega") {
                $0.hidden = true
            }
            <<< SwitchRow() {
                $0.tag = "same_address"
                $0.title = "Utilizar o endereço residendical para entrega?"
                $0.value = true
            }
            <<< IntFloatLabelRow() {
                $0.tag = "deliverycep"
                $0.title = "CEP"
                let formatter = NSNumberFormatter()
                formatter.maximumIntegerDigits = 8
                $0.formatter = formatter
                $0.hidden = "$same_address == true"
                }.onChange { row in self.defaultOnChangeCells(row) }
            <<< TextFloatLabelRow() {
                $0.tag = "deliveryaddress"
                $0.title = "Endereço"
                $0.hidden = "$same_address == true"
            }.onChange { row in self.defaultOnChangeCells(row) }
            <<< IntFloatLabelRow() {
                $0.tag = "deliverynumber"
                $0.title = "Número"
                $0.hidden = "$same_address == true"
            }.onChange { row in self.defaultOnChangeCells(row) }
            <<< TextFloatLabelRow() {
                $0.tag = "deliverycomplement"
                $0.title = "Complemento"
                $0.value = ""
                $0.hidden = "$same_address == true"
                }.onChange { row in self.defaultOnChangeCells(row) }
            <<< TextFloatLabelRow() {
                $0.tag = "deliveryneighborhood"
                $0.title = "Bairro"
                $0.hidden = "$same_address == true"
            }.onChange { row in self.defaultOnChangeCells(row) }
            <<< TextFloatLabelRow() {
                $0.tag = "deliverycity"
                $0.title = "Cidade"
                $0.value = "Porto Alegre"
                $0.disabled = true
                $0.hidden = "$same_address == true"
            }.onChange { row in self.defaultOnChangeCells(row) }
            <<< TextFloatLabelRow() {
                $0.tag = "deliveryuf"
                $0.title = "Estado"
                $0.value = "RS"
                $0.disabled = true
                $0.hidden = "$same_address == true"
            }.onChange { row in self.defaultOnChangeCells(row) }
    }
    
    /* Set the cell alert animation fade. Each different row type has one callback */
    func animatedCellAlert (bc: BaseCell) {
        if (bc.baseRow.baseValue != nil) && (bc.baseRow.tag != "reenterpassword") {
            return;
        }

        bc.alpha = 0

        UIView.animateWithDuration(2.0, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.TransitionNone, animations: {
                    bc.alpha = 1.0
                    bc.layer.borderColor = UIColor.redColor().CGColor
                    bc.layer.borderWidth = 0.5
                  }, completion: nil)
    }
    
    func defaultOnChangeCells (br: BaseRow) {
        if (br.baseValue == nil) || (String(br.baseValue).isEmpty) {
            br.baseCell.layer.borderWidth = 0.5
            br.baseCell.layer.borderColor = UIColor.redColor().CGColor
        } else {
            br.baseCell.layer.borderColor = UIColor.redColor().CGColor
            br.baseCell.layer.borderWidth = 0.0
        }
    }
    
    func isObligatory (tag: String) -> Bool {
        switch tag {
        case "complement":
            fallthrough
        case "birthdate":
            return false;
        default:
            return true;
        }
    }
    
    @IBAction func ProceedAction(sender: AnyObject) {
        self.tableView?.userInteractionEnabled = false
        self.navigationItem.title = "Enviando dados"
        
        newAddress = api.addAddress()
        newUser = try! api.addUser()
        
        /* Check for empty obligatory fieds in the form */
        let baserows = form.rows.enumerate()
        for (br) in baserows {
            if (isObligatory(br.1.tag!)) {
                if (br.1.baseValue == nil) || (String(br.1.baseValue).isEmpty) {
                    print("Not ok for \(br.1.tag)")
                    let indexPath = br.1.indexPath()

                    br.1.hightlightCell()
                    self.tableView?.scrollToRowAtIndexPath(indexPath!, atScrollPosition: UITableViewScrollPosition.Middle, animated: true)
                    self.tableView?.userInteractionEnabled = true
                    self.navigationItem.title = "Novo Usuário"
                    return;
                }
            }
            switch br.1.tag! {
            case "birthdate":
                break
            case "name":
                newUser!.fullName = String(br.1.baseValue!)
                break
            case "email":
                newUser!.email = String(br.1.baseValue!)
                newUser!.login = String(br.1.baseValue!)
                break
            case "password":
                newUser!.password = String(br.1.baseValue!)
                break
            case "reenterpassword":
                if (newUser!.password != String(br.1.baseValue!)) {
                    br.1.hightlightCell()
                    let indexPath = br.1.indexPath()
                    self.tableView?.scrollToRowAtIndexPath(indexPath!, atScrollPosition: UITableViewScrollPosition.Middle, animated: true)
                    print("Password reentered incorrectly.")
                    self.tableView?.userInteractionEnabled = true
                    self.navigationItem.title = "Novo Usuário"
                    return;
                }
                break
            case "cep":
                newAddress!.zipcode = String(br.1.baseValue!)
                break;
            case "cpf":
                newUser!.cpf = String(br.1.baseValue!)
                break;
            case "phone":
                newUser!.residentialPhone = String(br.1.baseValue!)
                break;
            case "cellphone":
                newUser!.cellPhone = String(br.1.baseValue!)
                break;
            case "number":
                let no = br.1.baseValue as! NSNumber
                newAddress?.number = no
                break;
            case "address":
                newAddress!.address = String(br.1.baseValue!)
                break;
            case "complement":
                newAddress!.complement = String(br.1.baseValue!)
                break;
            case "neighborhood":
                newAddress!.neighborhood = String(br.1.baseValue!)
                break;
            case "city":
                newAddress!.city = String(br.1.baseValue!)
                break;
            case "uf":
                newAddress!.state = String(br.1.baseValue!)
                break;
            default:
                newDeliveryAddress = api.addAddress()
                deliveryAddressCases(br.1, newAddress: newDeliveryAddress!)
                break;
            }
        }
        
        /* This call for the API, when finished, calls the newUserSynched callback */
        api.validateUserCreation(newUser!, address: newAddress!)
    }
    
    func deliveryAddressCases(br: BaseRow, newAddress: Address) {
        switch br.tag! {
        case "deliverycep":
            newAddress.zipcode = String(br.baseValue)
            break;
        case "deliverynumber":
            let no = br.baseValue as! NSNumber
            newAddress.number = no
            break;
        case "deliveryaddress":
            newAddress.address = String(br.baseValue)
            break;
        case "deliverycomplement":
            newAddress.complement = String(br.baseValue)
            break;
        case "deliveryneighborhood":
            newAddress.neighborhood = String(br.baseValue)
            break;
        case "deliverycity":
            newAddress.city = String(br.baseValue)
            break;
        case "deliveryuf":
            newAddress.state = String(br.baseValue)
            break;
        default:
            print("unknown user form tag \(br.tag)")
            break;
        }
    }
    
    func newUserSynched(notification: NSNotification) {
        let userInfo = notification.userInfo as! [String: AnyObject]
        let status = userInfo["status"] as! Int

        if (status != 200) {
            popup.popupAlert(PopupMessages.UserCreateFailed.Title, message: PopupMessages.UserCreateFailed.Message, button: PopupMessages.UserCreateFailed.Button, view: self)

            do {
                try api.removeUser((newUser?.login)!)
                try api.removeAddress((newAddress?.address)!)
                try api.userUnauthenticate()
            } catch {
                print("newUserSynched(): failed removing user/addresses after unsuccessful user creation.")
            }
            self.tableView?.userInteractionEnabled = true
            self.navigationItem.title = "Novo Usuário"
            return;
        }
        
        let user = userInfo["user"]
        let login = user!["email"] as! String
        let token = user!["token"] as! String
        let token_expiration = user!["token_expiration"] as! String

        do {
            try api.userAuthentication(login, token: token, expireDate: token_expiration)
        } catch {
            print("newUserSynched(): userAuthentication failed")
        }
        
        self.performSegueWithIdentifier("NewUserToOrderSegue", sender: self)
    }

}