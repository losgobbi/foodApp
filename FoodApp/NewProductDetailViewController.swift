//
//  NewProductDetailViewController.swift
//  FoodApp
//
//  Created by Leandro Silveira on 22/08/16.
//  Copyright © 2016 Hagen. All rights reserved.
//

import UIKit
import CoreData

class NewProductDetailViewController: UIViewController {
    
    /* Outlets */
    @IBOutlet weak var productImage: UIImageView!
    @IBOutlet weak var productName: UILabel!
    @IBOutlet weak var productPrice: UILabel!
    @IBOutlet weak var productDiscount: UILabel!
    @IBOutlet weak var productDescription: UILabel!
    @IBOutlet weak var scrollTopView: UIView!
    @IBOutlet weak var scrollHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var quantLabe: UILabel!
    @IBOutlet weak var minusButton: UIButton!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var bookMarkBt: UIButton!
    @IBOutlet weak var addButton: UIButton!
    
    /* Control */
    var product: Product?
    private var popup = PopupAlertView()

    /* Api reference */
    private var api = FoodApp.sharedInstance
    
    /* Delegates */
    private var badgeDelegate: UpdateBadgeDelegate? = nil
    
    override func viewDidLoad() {
        let backView = UIView(frame: CGRectMake(0, 0, nvLogoWidth, nvLogoHeight))
        let titleImageView = UIImageView(image: UIImage(named: "logo-foodApp.png"))
        
        titleImageView.frame = CGRectMake(0, nvStatusBarHeight, nvLogoWidth, nvLogoHeight)
        backView.addSubview(titleImageView)
        self.navigationItem.titleView = backView
        self.navigationController?.navigationBar.layoutIfNeeded()
        
        do {
            if (try api.isProductInBookMarks(product!)) {
                bookMarkBt.selected = true
            }
        } catch let error as NSError {
            print("NewProductDetailViewController(): Unable to check contains during viewDidLoad. Error = \(error)")
        }
        
        bookMarkBt.setBackgroundImage(UIImage(named: "star"), forState: UIControlState.Normal)
        bookMarkBt.setBackgroundImage(UIImage(named: "starFilled"), forState: UIControlState.Selected)
        
        NSNotificationCenter.defaultCenter().postNotificationName(FoodAppNotifications.ImageNotification.rawValue, object: self, userInfo: ["imageView": productImage, "product": product!])
        
        productName.text = product?.name
        
        if isIpad() {
            productName.font = UIFont(name: "Lato-Regular", size: 24)
            productDiscount.font = UIFont(name: "Lato-Regular", size: 24)
            productPrice.font = UIFont(name: "Lato-Regular", size: 24)
            productDescription.font = UIFont(name: "Lato-Regular", size: 24)
        }
        
        if (product!.discount != true) {
            productDiscount.hidden = true
            productPrice.text = String.localizedStringWithFormat("R$ %.2f", (product?.price)!)
            productPrice.sizeToFit()

        } else {
            productDiscount.hidden = false
            
            let discountFormatted = String.localizedStringWithFormat("De R$ %.2f", (product?.price)!)
            let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: "  \(discountFormatted)  ")
            
            attributeString.addAttribute(NSStrikethroughStyleAttributeName, value: 2, range: NSMakeRange(0, attributeString.length))
            
            productPrice.attributedText = attributeString
            productPrice.sizeToFit()
            productPrice.font = productPrice.font.fontWithSize(15)
            productDiscount.text = String.localizedStringWithFormat("por R$ %.2f", (product?.discountPrice)!)
            productDiscount.sizeToFit()
        }
        if (product?.desc.isEmpty == true) {
            productDescription.text = "Sem descrição"
        } else {
            productDescription.text = product?.desc
        }        
        
        self.view.layoutIfNeeded()

        /* init delegates */
        let barViewControllers = self.tabBarController!.viewControllers
        let navController = barViewControllers![carControllerIndex] as! UINavigationController
        let carController = navController.viewControllers[0] as! CarTableViewController
        
        badgeDelegate = carController
    }
    
    override func viewDidLayoutSubviews() {
        scrollHeightConstraint.constant = productDescription.frame.origin.y + productDescription.frame.height + addButton.frame.height
    }
    
    @IBAction func incrementProduct(sender: AnyObject) {
        var count = Int(quantLabe.text!)! + 1
        if (count >= maxProductAmount) {
            count = maxProductAmount
            plusButton.enabled = false
        }
        quantLabe.text = "\(count)"
        minusButton.enabled = true
    }
    
    @IBAction func decrementProduct(sender: AnyObject) {
        let count = Int(quantLabe.text!)
        plusButton.enabled = true
        if (count!-1 >= 1) {
            quantLabe.text = "\(count!-1)"
        }
        
        if (count!-1 == 1) {
            minusButton.enabled = false
        }
    }
    
    @IBAction func bookMarkAdd(sender: UIButton!) {
        sender.selected = !sender.selected;
        do {
            if (sender.selected == true) {
                try api.addUserBookMark(product!)
            } else {
                try api.remUserBookMark(product!)
            }
        } catch let error as NSError {
            print("bookMarkAdd(): Unable to add/rem Product = \(product!.id) in Bk. Error = \(error)")
        }
        let transitionOptions = UIViewAnimationOptions.TransitionFlipFromRight
        UIView.transitionWithView(sender, duration: 0.5, options: transitionOptions, animations: {
            }, completion: { finished in
        })
    }
    
    @IBAction func addProduct(sender: AnyObject) {
    
        let nProduct = Int(quantLabe.text!)
        
        do {
            try api.addProductToUserCar(product!, num: nProduct!)
            badgeDelegate?.setBadgeIcon()
        } catch let error as NSError {
            print("addButtonAction(): Unable to add/rem Product = \(product!.id) in Car. Error = \(error)")
            popup.popupAlert(PopupMessages.CantAddProduct.Title,
                message: PopupMessages.CantAddProduct.Message,
                button: PopupMessages.CantAddProduct.Button, view: self)
            return
        }
        self.navigationController?.popViewControllerAnimated(true)
    }
}