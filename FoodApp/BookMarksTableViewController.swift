//
//  BookMarksTableViewController.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 4/5/15.
//  Copyright (c) 2015 Hagen. All rights reserved.
//

import UIKit

class BookMarksTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private var api = FoodApp.sharedInstance
    private var popup = PopupAlertView()

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        
        let backView = UIView(frame: CGRectMake(0, 0, nvLogoWidth, nvLogoHeight))
        let titleImageView = UIImageView(image: UIImage(named: "logo-foodApp.png"))
        
        titleImageView.frame = CGRectMake(0, nvStatusBarHeight, nvLogoWidth, nvLogoHeight)
        backView.addSubview(titleImageView)
        self.navigationItem.titleView = backView
        self.navigationController?.navigationBar.layoutIfNeeded()
        
        /* use default edit button */
        self.editButtonItem().title = "Editar"
        self.tableView.editing = false
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
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

    override func viewDidAppear(animated: Bool) {
        tableView.reloadData()
        if (api.checkNetwork() != true) {
            popup.popupAlert(PopupMessages.NoInternet.Title, message: PopupMessages.NoInternet.Message, button: PopupMessages.NoInternet.Button, view: self)
            return
        }
    }

    func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String? {
        return "Remover"
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Adicione seu prato favorito na cesta"
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        do {
            switch editingStyle {
            case .Delete:
                /* remove from the favorites */
                let bookMarks = try api.getUserBookMarks()
                let product = bookMarks[indexPath.row]
                try api.remUserBookMark(product)
                /* remove the deleted item from the `UITableView` */
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                
                /* report this change to viewcontroller */
                NSNotificationCenter.defaultCenter().postNotificationName(
                    CtrNotifications.BkTableContentChanged.rawValue, object: nil,
                    userInfo: ["ProductChanged" : product])
            default:
                return
            }
        } catch let error as NSError {
            print("Unable to commitEditingStyle in Bk. Error = \(error)")
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("bookmarkcell",
            forIndexPath: indexPath) as! BookMarkCell
    
        do {
            let bookMarks = try api.getUserBookMarks()
            let product = bookMarks[indexPath.row]
            cell.productName.text = product.name
            cell.addToBasket.tag = indexPath.row
            cell.addToBasket.addTarget(self, action: #selector(BookMarksTableViewController.actionAddToBasket(_:)), forControlEvents: UIControlEvents.TouchUpInside)
            cell.addToBasket.selected = try api.isProductInCar(product)
        } catch let error as NSError {
            print("Unable to cellForRowAtIndexPath in Bk. Error = \(error)")
        }
        return cell
    }
    
    func actionAddToBasket(sender: UIButton) {
        if self.tableView.editing == true {
            return
        }
        
        do {
            let bookmark = try api.getUserBookMarks()
            sender.alpha = 0.0
            UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.TransitionNone, animations: { sender.alpha = 1.0
                }, completion: nil)
            if (sender.selected == false) {
                sender.selected = true
                try api.addProductToUserCar(bookmark[sender.tag])
            } else {
                sender.selected = false
                try api.remProductFromUserCar(bookmark[sender.tag])
            }
            /* report this change to viewcontroller */
            NSNotificationCenter.defaultCenter().postNotificationName(
                CtrNotifications.BkTableContentChanged.rawValue, object: nil,
                userInfo: ["ProductChanged" : bookmark[sender.tag]])
        } catch let error as NSError {
            print("Unable to actionAddToBasket in Bk. Error = \(error)")
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = try? api.getUserBookMarks().count
        return count ?? 0
    }
}
