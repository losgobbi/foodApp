//
//  OrderViewController2.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 4/21/16.
//  Copyright © 2016 Hagen. All rights reserved.
//

import Foundation
import Eureka

class OrderViewController : FormViewController {
    
    /* Api reference */
    private var api = FoodApp.sharedInstance
    private var orderContainer: Order?
    
    /* General stuff */
    private var popup = PopupAlertView()
    private let progressMsg = "...Validando Pedido"
    private var formModal: Bool = false
    private var progressBar: UIActivityIndicatorView?
    private var addressOptions: [String: Int] = Dictionary()
    private var payOptions = [ "Cartão de Crédito", "Cheque", "Dinheiro" ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            try api.getUserAddresses().forEach { (address) -> () in
                addressOptions[address.address!] = Int(address.id!)
            }
        } catch {
            print("OrderViewController viewDidLoad(): Cannot get user addresses to list.")
        }
        
        /* Default actions for row types */
        DateInlineRow.defaultOnCellHighlight = { cell,
            row in self.animatedCellAlert(row.baseCell) }
        TimeInlineRow.defaultOnCellHighlight = { cell,
            row in self.animatedCellAlert(row.baseCell) }
        ActionSheetRow<String>.defaultOnCellHighlight = { cell,
            row in self.animatedCellAlert(row.baseCell) }
        TextAreaRow.defaultOnCellHighlight = { cell,
            row in self.animatedCellAlert(row.baseCell) }
        PushRow<String>.defaultOnCellHighlight = { cell,
            row in self.animatedCellAlert(row.baseCell) }

        form
            +++ Section("Forma de pagamento")
            <<< ActionSheetRow<String>() {
                $0.selectorTitle = "Qual a forma de pagamento?"
                for opt in payOptions {
                    $0.options.append(opt)
                }
                $0.tag = "payoption"
                }.onChange { row in self.defaultOnChangeCells(row) }
            
            +++ Section("Escolha a data")
            <<< DateInlineRow() {
                $0.title = "Informe o dia"
                $0.tag = "date"
                let fmt1 = NSDateFormatter()
                fmt1.locale = NSLocale(localeIdentifier: "en_US_POSIX") /* QA1480 */
                fmt1.dateFormat = "dd/MM/yyyy"
                $0.dateFormatter = fmt1
                $0.baseValue = NSDate()
                $0.minimumDate = NSDate()
                $0.displayValueFor = {
                    guard let date = $0 else {
                        return fmt1.stringFromDate(NSDate())
                    }
                    return fmt1.stringFromDate(date)
                }
                }.onChange { row in self.defaultOnChangeCells(row) }
            
            +++ Section("Escolha o horário desejado")
            <<< ActionSheetRow<String>() {
                $0.title = "Informe o horário"
                $0.selectorTitle = "Escolha o horário desejado"
                $0.tag = "time"
                $0.cellUpdate({ (cell, row) in
                    if let selectedDate = self.form.rowByTag("date")?.baseValue as? NSDate {
                        let newOptions = self.retrieveDeliveryIntervalsOptions(selectedDate)
                        // reset selected option
                        if row.options != newOptions {
                            row.options = newOptions
                            row.baseValue = nil
                        }
                    }
                })
                $0.options = retrieveDeliveryIntervalsOptions()
                }.onChange { row in self.defaultOnChangeCells(row) }
            
            +++ Section("Escolha endereço")
            <<< ActionSheetRow<String>() {
                $0.selectorTitle = "Qual endereço você quer utilizar?"
                for (address, _) in addressOptions {
                    $0.options.append(address)
                }
                $0.tag = "address"
                }.onChange { row in self.defaultOnChangeCells(row) }

            +++ Section("Informações Adicionais")
            <<< TextAreaRow() {
                $0.title = "Informações adicionais"
                $0.tag = "info"
                $0.placeholder = "Utilize o campo abaixo para informações adicionais..."
            } .onChange { row in self.defaultOnChangeCells(row) }
        
        /* api */
        do {
            if let order = try api.getUserOrder() {
                orderContainer = order
            }
        } catch let error as NSError {
            print("OrderViewController viewDidLoad(): Unable to build order. Error = \(error)")
        }
        
        /* nav appearance */
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancelar",
            style: UIBarButtonItemStyle.Plain, target: self, action: #selector(OrderViewController.dismissModalView))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Voltar",
            style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector:#selector(OrderViewController.orderCompleted(_:)),
            name: FoodAppNotifications.OrderDispatched.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector:#selector(OrderViewController.orderCompleted(_:)),
            name: FoodAppNotifications.OrderDispatched.rawValue, object: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    /*
     * Opções de horário. Retornar as opções possíveis para hoje,
     * quais sejam, aquelas para as quais falta mais de uma hora.
     * 9h-11h
     * 12h-14h
     * 14h-16h
     * 16h-18h
     */
    func retrieveDeliveryIntervalsOptions (date: NSDate? = nil) -> [String] {
        let components = NSCalendar.currentCalendar().components([.Hour, .Minute, .Day, .Month, .Year], fromDate: NSDate())
        let hourOffset = Float(1) //one hour
        let minutes2hours = Float(components.minute)/60
        let due_time = Float(components.hour) + minutes2hours + hourOffset
        let intervals = api.getOrderIntervals()

        if let selectedDate = date {
            let selectComponents = NSCalendar.currentCalendar().components([.Hour, .Minute, .Day, .Month, .Year], fromDate: selectedDate)
            if selectComponents.day > components.day || selectComponents.month > components.month || selectComponents.year > components.year {
                return intervals
            }
        }
        
        if (due_time < 11) {
            return intervals
        }
        if (due_time < 14) {
            return Array(intervals.dropFirst())
        }
        if (due_time < 16) {
            return Array(intervals.dropFirst(2))
        }
        if (due_time < 18) {
            return Array(intervals.dropFirst(3))
        }

        return [ "Não há horários para hoje." as String ];
    }
    
    /* Set the cell alert animation fade. Each different row type has one callback */
    func animatedCellAlert (bc: BaseCell) {
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
        
        /* customization */
        switch br.tag! {
        case "date":
            form.rowByTag("time")?.updateCell()
            form.rowByTag("time")?.reload()
        default:
            break
        }
    }
    
    func orderCompleted(notification: NSNotification) {
        let userInfo = notification.userInfo as! [String: AnyObject]
        self.navigationItem.leftBarButtonItem?.enabled = true
        self.navigationItem.rightBarButtonItem?.enabled = true
        
        self.navigationItem.titleView = nil
        if let orderStatus = userInfo["orderStatus"] as? Int {
            let msg = userInfo["msg"] as! String
            //progressBar!.stopAnimating()
            
            /* operation failed */
            if orderStatus == 400 || orderStatus != 200 {
                popup.popupAlert(PopupMessages.OrderInvalid.Title,
                    message: PopupMessages.OrderInvalid.Message +
                    (msg.isEmpty ? "" : " (Erro:\(msg))"),
                    button: PopupMessages.OrderInvalid.Button, view: self)
                return
            }
            
            /* clear */
            do {
                try api.remUserOrder()
                try api.remUserCar()
                
                /* update order time */
                let cl = try api.getUser()
                cl!.lastOrderTime = NSDate().timeIntervalSinceReferenceDate
                
                NSNotificationCenter.defaultCenter().removeObserver(self)
                /* here the car is empty, so post to view controller */
                NSNotificationCenter.defaultCenter().postNotificationName(
                    CtrNotifications.CarTableContentChanged.rawValue, object: nil,
                    userInfo: nil)
                
                let barViewControllers = self.presentingViewController as! UITabBarController
                let firstNavc = barViewControllers.viewControllers![viewControllerIndex] as! UINavigationController
                let firstVc = firstNavc.viewControllers[0] as! NewIntroViewController
                
                /* remove nav controller */
                self.dismissViewControllerAnimated(true, completion: nil)
                
                /* go to the root (car controller) */
                barViewControllers.selectedIndex = viewControllerIndex
                self.popup.popupAlert(PopupMessages.OrderValid.Title,
                    message: PopupMessages.OrderValid.Message,
                    button: PopupMessages.OrderValid.Button, view: firstVc)
            } catch let error as NSError {
                print("orderCompleted(): Unable to handle order. Error = \(error)")
            }
        }
    }
    
    func validPreOrder(inout Title: String, inout Message: String, inout Button: String) -> Bool {
        var valid: Bool = true
        if let order = try? api.getUserOrder() {
            /*
            * Rules:
            * 1) "Fizemos um intervalos de 2 horas por pedido até as 16h."
            * 2) "Após as 16 h fica para o outro dia."
            */
            let lastTime = NSDate(timeIntervalSinceReferenceDate: order!.orderClient!.lastOrderTime)
            let lastTimeTxt = formatDate2string(lastTime, format: "dd/MM/yyyy")
            
            /* check rule 1 */
            if lastTimeTxt != "01/01/1970" {
                let elapsed = NSCalendar.currentCalendar().components(NSCalendarUnit.Hour,
                    fromDate: lastTime, toDate: NSDate(), options: [])
                print("validatePreOrder() LastTime = \(lastTimeTxt), elapsed \(elapsed.hour) hours")
                if elapsed.hour > 2 {
                    valid = true
                } else {
                    Title = PopupMessages.OrderInvalidTimeWindow.Title
                    Message = PopupMessages.OrderInvalidTimeWindow.Message
                    Button = PopupMessages.OrderInvalidTimeWindow.Button
                    return false
                }
                
            }
            
            /* check rule 2 */
            let greg = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
            let cmp = greg!.components(NSCalendarUnit.Hour, fromDate: NSDate())
            
            /* greg uses 24 hours format */
            if cmp.hour >= 16 && cmp.hour < 24 {
                let date = NSDate(timeIntervalSinceReferenceDate: orderContainer!.date)
                let now = NSDate()
                
                /* if is not today */
                let dateTxt = formatDate2string(date, format: "dd/MM/yyyy")
                let nowTxt = formatDate2string(now, format: "dd/MM/yyyy")
                
                print("validatePreOrder() after 16:00pm, dateSet = \(dateTxt) now = \(nowTxt)")
                if nowTxt != dateTxt {
                    valid = true
                } else {
                    Title = PopupMessages.OrderInvalidTime.Title
                    Message = PopupMessages.OrderInvalidTime.Message
                    Button = PopupMessages.OrderInvalidTime.Button
                    valid = false
                }
            }
        }
        
        return valid
    }
    
    func dismissModalView() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func isObligatory (tag: String, value: Any?) -> Bool {
        switch tag {
        case "info":
            return false
        case "time":
            if let val = value as? String {
                if val == "Não há horários para hoje." {
                    return true
                } else {
                    return false
                }
            }
            return true
        default:
            return true
        }
    }

    /* validate 'Pedido' information */
    @IBAction func validateOrder(sender: UIBarButtonItem) {
        
        /* Check for empty obligatory fields in the form and build container */
        let baserows = form.rows.enumerate()
        for br in baserows {
            /*
             * Avoid crashes when the row is in the "expanded" state.
             * In that state, baseRows is higher than we are expecting so
             * some .tags are nil.
             */
            let validTag = br.1.tag
            if validTag == nil {
                continue
            }
            
            if (isObligatory(br.1.tag!, value: br.1.baseValue)) {
                if (br.1.baseValue == nil) || (String(br.1.baseValue).isEmpty) || (br.1.tag! == "time")  {
                    let indexPath = br.1.indexPath()
                    br.1.hightlightCell()
                    self.tableView?.scrollToRowAtIndexPath(indexPath!, atScrollPosition: UITableViewScrollPosition.Middle, animated: true)
                    return;
                }
            }
            
            /*
             * XXX baseValue for date and time is formatted like:
             * 2016-04-22 20:32:13 +0000 (UTC timezone)
             */
            switch br.1.tag! {
            case "date":
                let strDate = String(br.1.baseValue!)
                let fmt1 = NSDateFormatter()
                fmt1.dateFormat = "yyyy-MM-dd HH:mm:ss xx"
                fmt1.locale = NSLocale(localeIdentifier: "en_US_POSIX") /* QA1480 */
                if let date = fmt1.dateFromString(strDate) {
                    orderContainer!.date = date.timeIntervalSinceReferenceDate
                }
                break
            case "time":
                let strTime = api.getOrderHalfIntervals(String(br.1.baseValue!))
                let fmt2 = NSDateFormatter()
                fmt2.dateFormat = "HH"
                fmt2.locale = NSLocale(localeIdentifier: "en_US_POSIX") /* QA1480 */
                if let time = fmt2.dateFromString(strTime) {
                    orderContainer!.time = time.timeIntervalSinceReferenceDate
                }
                break
            case "address":
                let addressKey = String(br.1.baseValue!)
                let addId = addressOptions[addressKey]!
                orderContainer!.deliveryAddressId = Int32(addId)
                break
            case "info":
                if (br.1.baseValue == nil) || (String(br.1.baseValue).isEmpty) {
                    break
                }
                orderContainer!.addInfo = String(br.1.baseValue!)
                break
            case "payoption":
                if (br.1.baseValue == nil) || (String(br.1.baseValue).isEmpty) {
                    break
                }
                orderContainer!.pay = String(br.1.baseValue!)
                break
            default:
                break
            }
        }
        
        self.navigationItem.leftBarButtonItem?.enabled = false
        self.navigationItem.rightBarButtonItem?.enabled = false
        
        /* start progress */
        /*showNavProgressBar(progressMsg,
            navtitleView: &self.navigationItem.titleView, viewIndicator: &progressBar)*/
        
        /* send order */
        do {
            let cl = try api.getUser()
            api.dispatchOrder(cl!)
        } catch let error as NSError {
            print("validateOrder(): Unable to validate. Error = \(error)")
        }
    }
}
