//
//  ProductViewController.swift
//  FoodApp
//
//  Created by Leandro Silveira on 10/04/16.
//  Copyright © 2016 Hagen. All rights reserved.
//

import UIKit

class ProductViewController: UIViewController, UIGestureRecognizerDelegate {

    /* Outlets */
    @IBOutlet weak var productName: UILabel!
    @IBOutlet weak var productImage: UIImageView!
    @IBOutlet weak var productDesc: UITextView!
    @IBOutlet weak var productFilterImage: UIImageView!
    @IBOutlet weak var productPrice: UILabel!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var bookmarkButton: UIButton!
    @IBOutlet weak var productDiscountPrice: UILabel!
    @IBOutlet weak var productActivity: UIActivityIndicatorView!
    
    var cell: ProductCollectionViewCell?
    var tapBGGesture: UITapGestureRecognizer!
    var api = FoodApp.sharedInstance
    var badgeDelegate: UpdateBadgeDelegate?
    
    deinit {
        cell?.productImage.removeObserver(self, forKeyPath: "image")
    }

    override func viewDidLoad() {
        productName.text = cell?.productName.text
        productImage.image = cell?.productImage.image
        productDesc.text = cell?.productDesc
        productFilterImage.image = cell?.productLine.image
        
        cell?.productImage.addObserver(self, forKeyPath: "image", options: NSKeyValueObservingOptions.New, context: nil)
        
        if (productImage.image == nil) {
            productActivity.hidden = false
            productActivity.startAnimating()
        } else {
            productActivity.hidden = true
            productActivity.stopAnimating()
        }
        
        do {
            if (try api.isProductInCar((cell?.product)!)) {
                addButton.selected = true
            }
        } catch let error as NSError {
            print("ViewDidLoad(): Unable to update addButton state. Error = \(error)")
        }
        
        do {
            if (try api.isProductInBookMarks((cell?.product)!)) {
                bookmarkButton.selected = true
            }
        } catch let error as NSError {
            print("ViewDidLoad(): Unable to update addButton state. Error = \(error)")
        }
        
        
        bookmarkButton.setBackgroundImage(UIImage(named: "star"), forState: UIControlState.Normal)
        bookmarkButton.setBackgroundImage(UIImage(named: "starFilled"), forState: UIControlState.Selected)
        
        addButton.addTarget(self, action: #selector(self.addButtonAction(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        addButton.setBackgroundImage(UIImage(named: "bluebutton"), forState: UIControlState.Normal)
        addButton.setBackgroundImage(UIImage(named: "greenbutton"), forState: UIControlState.Selected)
        addButton.setTitle("Adicionado", forState: .Selected)
        addButton.setTitle("Adicionar", forState: .Normal)
        addButton.titleLabel!.font = UIFont(name: "Lato-Regular", size: 20)
        badgeDelegate = cell?.badgeDelegate
        
        
        if (cell?.product!.discount == false) {
            productPrice.hidden = false
            productDiscountPrice.hidden = true
            productPrice.text = cell?.productPrice
            productPrice.backgroundColor = UIColor(patternImage: UIImage(named: "pricebg")!)
            productPrice.layer.masksToBounds = true
            productPrice.layer.cornerRadius = 10.0
            productPrice.sizeToFit()
            
        } else {
            productPrice.hidden = false
            productDiscountPrice.hidden = false
            
            let price = cell?.product!.price
            let discount = cell?.product!.discountPrice
            
            let discountFormatted = String.localizedStringWithFormat("R$ %.2f", price!)
            
            let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: "  \(discountFormatted)  ")
            attributeString.addAttribute(NSStrikethroughStyleAttributeName, value: 2, range: NSMakeRange(0, attributeString.length))
            
            productDiscountPrice.attributedText = attributeString
            productDiscountPrice.sizeToFit()
            productDiscountPrice.backgroundColor = UIColor.blackColor()
            productDiscountPrice.layer.masksToBounds = true
            productDiscountPrice.layer.cornerRadius = 10.0
            
            productPrice.text = String.localizedStringWithFormat("  R$ %.2f  ", discount!)
            productPrice.sizeToFit()
            
            productPrice.backgroundColor = UIColor(patternImage: UIImage(named: "pricebg")!)
            productPrice.layer.masksToBounds = true
            productPrice.layer.cornerRadius = 10.0
        }
    }
    
    func addButtonAction(sender: UIButton!) {
        let pd = cell?.product
        sender.selected = !sender.selected
        
        do {
            if (sender.selected == true) {
                try api.addProductToUserCar(pd!)
            } else {
                try api.remProductFromUserCar(pd!)
            }
        } catch let error as NSError {
            print("addButtonAction(): Unable to add/rem Product = \(pd!.id) in Car. Error = \(error)")
        }
        
        badgeDelegate?.setBadgeIcon()
        
        let transitionOptions = UIViewAnimationOptions.TransitionFlipFromBottom
        UIView.transitionWithView(sender, duration: 0.5, options: transitionOptions, animations: {
            }, completion: { finished in
        })
    }
    
    override func viewDidAppear(animated: Bool) {
        tapBGGesture = UITapGestureRecognizer(target: self, action: #selector(ProductViewController.settingsBGTapped(_:)))
        tapBGGesture.delegate = self
        tapBGGesture.numberOfTapsRequired = 1
        tapBGGesture.cancelsTouchesInView = false
        self.view.window!.addGestureRecognizer(tapBGGesture)
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.view.window!.removeGestureRecognizer(tapBGGesture)
    }

    func settingsBGTapped(sender: UITapGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.Ended {
            if let presentedView = self.view {
                if !CGRectContainsPoint(presentedView.bounds, sender.locationInView(presentedView)) {
                    self.dismissViewControllerAnimated(true, completion: { () -> Void in
                    })
                }
            }
        }
    }
    
    @IBAction func bookmarkAdd(sender: AnyObject) {
        
            let pd = cell?.product
            bookmarkButton.selected = !bookmarkButton.selected;
            
            do {
                if (sender.selected == true) {
                    try api.addUserBookMark(pd!)
                } else {
                    try api.remUserBookMark(pd!)
                }
            } catch let error as NSError {
                print("bookMarkAdd(): Unable to add/rem Product = \(pd!.id) in Bk. Error = \(error)")
            }
            let transitionOptions = UIViewAnimationOptions.TransitionFlipFromRight
            UIView.transitionWithView(sender as! UIView, duration: 0.5, options: transitionOptions, animations: {
                }, completion: { finished in
            })
    }
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "image" {
            if let imgView = object as? UIImageView {
                if imgView.image != nil {
                    productActivity.stopAnimating()
                    productActivity.hidden = true
                    productImage.image = imgView.image
                } else {
                    productActivity.hidden = false
                    productActivity.startAnimating()
                }
            }
        }
    }
}
