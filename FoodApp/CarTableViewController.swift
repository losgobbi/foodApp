//
//  CarTableViewController.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 4/5/15.
//  Copyright (c) 2015 Hagen. All rights reserved.
//

import UIKit
import CoreData

class CarTableViewController: UIViewController, UITableViewDataSource,
    UITableViewDelegate, NSFetchedResultsControllerDelegate,UIPickerViewDataSource,
    UIPickerViewDelegate, UITextFieldDelegate, UpdateBadgeDelegate {

    private var popup = PopupAlertView()

    /* Outlets */
    @IBOutlet weak var tableView: UITableView!
    
    /* Model information */
    private var maxModelSection : Int = 0

    /* Table data */
    private var sum: Float = 0
    private var subTotal: Float = 0
    private var frete: Float = 0
    private var numberOfSections = 0
    private let extraSections = 2

    /* Api reference */
    private var api = FoodApp.sharedInstance
    private var apiCtx: NSManagedObjectContext?
    private var orderContainer: Order?
    
    /* Heights */
    private let CAR_ROW_HEIGHT: CGFloat = 75
    private let SUM_ROW_HEIGHT: CGFloat = 41
    private let SECTION_HEIGHT: CGFloat = 25
    
    /* Aditional cells */
    private let ROWS_EXTRA_SECTION_TOTAL         = 3
    private let ROWS_EXTRA_SECTION_DELIVERY_FORM = 1
    
    /* NFR */
    private var fetcher = NSFetchedResultsController()

    /* Product count */
    private var countPickerView = UIPickerView()
    private var accessoryBar: UIToolbar?
    private var activeTxtField: UITextField?
    private var toolBarHeight: CGFloat = 0
    private let PICKER_COUNT_COMPONENTS   = 1
    
    /* Picker */
    private var deliveryFormPickerView = UIPickerView()
    private var deliveryForms = [DeliveryForm]()
    
    override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector:#selector(CarTableViewController.keyboardWasShown(_:)), name: "UIKeyboardDidShowNotification",
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector:#selector(CarTableViewController.keyboardWillHiden), name: "UIKeyboardWillHideNotification",
            object: nil)
        
        let backView = UIView(frame: CGRectMake(0, 0, nvLogoWidth, nvLogoHeight))
        let titleImageView = UIImageView(image: UIImage(named: "logo-foodApp.png"))
        
        titleImageView.frame = CGRectMake(0, nvStatusBarHeight, nvLogoWidth, nvLogoHeight)
        backView.addSubview(titleImageView)
        self.navigationItem.titleView = backView
        self.navigationController?.navigationBar.layoutIfNeeded()
        
        
        /* init */
        apiCtx = api.getManagedContext()
        
        /* use default edit button */
        self.editButtonItem().title = "Editar"
        self.tableView.editing = false
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        
        countPickerView.backgroundColor = UIColor.whiteColor()
        countPickerView.delegate = self
        countPickerView.restorationIdentifier = "countPickerView"
        accessoryBar = createToolBarWithDoneButton(self, toolBarHeight: &toolBarHeight)
        
        deliveryFormPickerView.backgroundColor = UIColor.whiteColor()
        deliveryFormPickerView.delegate = self
        deliveryFormPickerView.restorationIdentifier = "deliveryFormPickerView"
    }
    
    //TODO is too heavy this build?
    //If so, we have to add a notification when user logs in
    override func viewWillAppear(animated: Bool) {
        /* build fetcher */
        fetcher = getFetchedResultController()
        fetcher.delegate = self
        try! fetcher.performFetch()

        do {
            if let order = try api.getUserOrder() {
                orderContainer = order
            } else {
                orderContainer = try api.buildUserOrderContainer()
            }
            
            deliveryForms = try api.getDeliveryForms()!
        } catch let error as NSError {
            print("CarTableViewController viewDidLoad(): Error = \(error)")
        }

        updateTable()
    }
    
    /** notifications **/
     
     /* discount the keyboard height from inset */
    func keyboardWasShown(notification: NSNotification) {
        let userInfo = notification.userInfo as! [String: AnyObject]
        let keyBoardInfo = userInfo["UIKeyboardFrameBeginUserInfoKey"] as! NSValue
        
        /* inset without keyboard */
        let keyBoardHeight = keyBoardInfo.CGRectValue().height
        let contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyBoardHeight, 0.0);
        self.tableView.contentInset = contentInsets
        self.tableView.scrollIndicatorInsets = contentInsets
        
        let newViewHeight = self.view.frame.size.height - keyBoardHeight - toolBarHeight;
        var superViewArea = self.view.frame
        superViewArea.size.height = newViewHeight
        
        if let editingTxtField = activeTxtField {
            /* if we have to scroll */
            if (!CGRectContainsPoint(superViewArea, editingTxtField.frame.origin) ) {
                self.tableView.scrollRectToVisible(editingTxtField.frame, animated: true)
            }
        }
    }
    
    func keyboardWillHiden() {
        self.tableView.contentInset = UIEdgeInsetsZero
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsZero
    }
    
    func updateTable() {
        do {
            maxModelSection = try api.getUserLineCar().count
        } catch let error as NSError {
            print("updateTable(): Unable to count line car. Error = \(error)")
        }
        
        /* force reload because 'sum' cells */
        tableView.reloadData()
        
        /* reload price */
        flushPrice()
        
        /* update badge */
        setBadgeIcon()
        
        /* avoid 'next' scene */
        if maxModelSection <= 0 {
            self.navigationItem.rightBarButtonItem?.enabled = false
        } else {
            self.navigationItem.rightBarButtonItem?.enabled = true
        }
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        self.tableView.setEditing(!self.tableView.editing, animated: animated)
        if editing {
            self.editButtonItem().title = "Pronto"
        } else {
            self.editButtonItem().title = "Editar"
        }
    }
    
    /* NFR */
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        updateTable()
    }
    
    func getFetchedResultController() -> NSFetchedResultsController {
        /* title section is line desc */
        return NSFetchedResultsController(fetchRequest: fetchRequest(),
            managedObjectContext: apiCtx!, sectionNameKeyPath: "productLine.name", cacheName: nil)
    }
    
    func fetchRequest() -> NSFetchRequest {
        let fetchRequest = NSFetchRequest(entityName: "Product")
        fetchRequest.predicate = NSPredicate(format: "productClientProductList != nil and productClientProductList.login == '\(api.getUserLogged())'")
        
        let sortCriteria1 = NSSortDescriptor(key: "productLine.name", ascending: true)
        let sortCriteria2 = NSSortDescriptor(key: "name", ascending: true)

        fetchRequest.sortDescriptors = [sortCriteria1, sortCriteria2]
        return fetchRequest
    }
    
    /* delegate/datasource */
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {        
        if (indexPath.section + 1) <= maxModelSection {
            return true
        }
        
        /* cant remove fixed cells */
        return false
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if (indexPath.section + 1) <= maxModelSection {
            return CAR_ROW_HEIGHT
        }
        return SUM_ROW_HEIGHT
    }

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return SECTION_HEIGHT
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        /* sum section */
        if (section + 1) > maxModelSection && (section + 1) < numberOfSections {
            return "Escolha a forma de entrega"
        }
        
        if (section + 1) == numberOfSections {
            return "Total"
        }
        
        /* product section */
        if let sections = fetcher.sections {
            let currentSection = sections[section]
            let pds = currentSection.objects as! [Product]
            return pds[0].productLine.name
        }

        return ""
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let product = fetcher.objectAtIndexPath(indexPath) as! Product

        do {
            /* remove object from core data */
            try api.remProductFromUserCar(product)
            
            /* report this change to viewcontroller */
            NSNotificationCenter.defaultCenter().postNotificationName(
                CtrNotifications.CarTableContentChanged.rawValue, object: nil,
                userInfo: ["ProductChanged" : product])
            
            let modelSec = try api.getUserLineCar().count
            if maxModelSection > modelSec {
                maxModelSection -= 1
            }
            
            /* erase delivery form if all elements were removed */
            if maxModelSection == 0 {
                orderContainer!.orderDeliveryForm = nil
            }
        } catch let error as NSError {
            print("Unable to commitEditingStyle in Car. Error = \(error)")
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        /* product section */
        if (indexPath.section + 1) <= maxModelSection {
            let cell = tableView.dequeueReusableCellWithIdentifier("carcell",
                forIndexPath: indexPath) as! CarCell
            let product = fetcher.objectAtIndexPath(indexPath) as! Product
            cell.productName.text = product.name
            let pdPrice = product.discount ? product.discountPrice: product.price
            let totalPrice = pdPrice * Float(product.productListCount)

            cell.productPrice.text = String.localizedStringWithFormat("%.2f", totalPrice)
            cell.productCount.inputView = countPickerView
            cell.productCount.tag = Int(product.id)
            cell.productCount.inputAccessoryView = accessoryBar
            cell.productCount.text = "\(product.productListCount)"
            
            /* remove cursor */
            cell.productCount.tintColor = UIColor.whiteColor()
            return cell
        } else if (indexPath.section + 1) < numberOfSections {
            /* delivery form section */
            let cell = tableView.dequeueReusableCellWithIdentifier("carcelldeliveryForm",
                forIndexPath: indexPath) as! CarCell
            cell.deliveryForm.inputView = deliveryFormPickerView
            cell.deliveryForm.inputAccessoryView = accessoryBar
            
            if let form = orderContainer!.orderDeliveryForm {
                cell.deliveryForm.text = form.name
            } else {
                cell.deliveryForm.text = "Escolha a forma de entrega"
            }
            return cell
        } else {
            /* sum section */
            switch indexPath.row {
            case 0:
                let sumCell = tableView.dequeueReusableCellWithIdentifier("carcellsub",
                    forIndexPath: indexPath) as! SumCel
                sumCell.subtotal.text = "Subtotal"
                sumCell.subtotalValue.text = String.localizedStringWithFormat("%.2f", subTotal)
                return sumCell
            case 1:
                let sumCell = tableView.dequeueReusableCellWithIdentifier("carcellfrete",
                    forIndexPath: indexPath) as! SumCel
                sumCell.freteTotal.text = "Frete"
                sumCell.freteTotalValue.text = String.localizedStringWithFormat("%.2f", frete)
                return sumCell
            default:
                let sumCell = tableView.dequeueReusableCellWithIdentifier("carcelltotal",
                    forIndexPath: indexPath) as! SumCel
                sumCell.total.text = "Total"
                sumCell.totalValue.text = String.localizedStringWithFormat("%.2f", sum)
                return sumCell
            }
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let sections = fetcher.sections {
            if sections.count <= 0 {
                return 0
            }
            numberOfSections = sections.count + extraSections
            return numberOfSections
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section + 1) <= maxModelSection {
            if let sections = fetcher.sections {
                let currentSection = sections[section]
                return currentSection.numberOfObjects
            }
        }
        
        if (section + 1) < numberOfSections {
            /* delivery section */
            return ROWS_EXTRA_SECTION_DELIVERY_FORM
        } else {
            /* last section */
            return ROWS_EXTRA_SECTION_TOTAL
        }
    }
    
    func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String? {
        return "Remover"
    }
    
    /* pickerview delegate/datasource */
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return PICKER_COUNT_COMPONENTS
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.restorationIdentifier! == "countPickerView" {
            return maxProductAmount
        } else {
            return deliveryForms.count
        }
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.restorationIdentifier! == "countPickerView" {
            return "\(row + 1)"
        } else {
            return deliveryForms[row].name
        }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.restorationIdentifier! == "deliveryFormPickerView" {
            let form = deliveryForms[row]
            orderContainer!.orderDeliveryForm = form
        }
    }

    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        /* cant erase current value of textfield */
        return false
    }
    
    /* textField editing */
    func textFieldDidBeginEditing(textField: UITextField) {
        activeTxtField = textField
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        activeTxtField = nil
    }
    
    func doneButtonAction(sender: UIButton) {
        if activeTxtField?.restorationIdentifier == "txtPdCount" {
            /* there is only one component, find row */
            let selRow = countPickerView.selectedRowInComponent(0)
            let cvalue = countPickerView.delegate!.pickerView!(countPickerView,
                titleForRow: selRow, forComponent: 0)
            
            /* update product count */
            do {
                let pd = try api.getProduct(activeTxtField!.tag)
                pd!.productListCount = Int16(NSNumberFormatter().numberFromString(cvalue!)!.integerValue)
            } catch let error as NSError {
                print("doneButtonAction(): Unable to change ProductCount Product = \(activeTxtField!.tag). Error = \(error)")
            }
            
            if let txt = activeTxtField {
                txt.resignFirstResponder()
            }
            
            /* reset picker to default and update table */
            countPickerView.selectRow(0, inComponent: 0, animated: false)
        } else {
            let selRow = deliveryFormPickerView.selectedRowInComponent(0)
            let form = deliveryForms[selRow]
            orderContainer!.orderDeliveryForm = form
        }

        updateTable()
    }
    
    /* price handling */
    func flushPrice() {
        var carSum : Float = 0.00
        
        do {
            let pds = try api.getUserProductCar()
            for pd in 0..<pds.count {
                let pdPrice = pds[pd].discount ? pds[pd].discountPrice: pds[pd].price
                carSum += (pdPrice * Float(pds[pd].productListCount))
            }
        } catch let error as NSError {
            print("flushPrice(): Unable to flush price. Error = \(error)")
        }
        
        /* sum is equal to subTotal */
        sum = carSum
        subTotal = sum
        
        frete = 0
        /* update 'frete' */
        if let df = orderContainer!.orderDeliveryForm {
            frete = df.price
            sum += frete
        }
    }
    
    /* update badge icon */
    func setBadgeIcon() {
        var badgeValue: Int = 0
        
        do {
            let pds = try api.getUserProductCar()
            for pd in 0..<pds.count {
                badgeValue += Int(pds[pd].productListCount)
            }
        } catch let error as NSError {
            print("setBadgeIcon(): Unable to change badge icon. Error = \(error)")
        }

        if badgeValue == 0 {
            self.navigationController?.tabBarItem.badgeValue = nil
        } else {
            self.navigationController?.tabBarItem.badgeValue = "\(badgeValue)"
        }
    }
    
    @IBAction func ProceedAction(sender: AnyObject) {
        if orderContainer!.orderDeliveryForm == nil {
            popup.popupAlert(PopupMessages.FillDeliveryForm.Title,
                message: PopupMessages.FillDeliveryForm.Message,
                button: PopupMessages.FillDeliveryForm.Button, view: self)
            return
        }
        
        self.performSegueWithIdentifier("checkoutOrderSegue", sender: self)
    }
    
}
