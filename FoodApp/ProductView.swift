//
//  ProductView.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 3/29/15.
//  Copyright (c) 2015 Hagen. All rights reserved.
//
//  Class used at scroll view content
//

import UIKit

class ProductView: UIView {

    /* View elements */
    private var productImage: UIImageView!
    private var lineImage: UIImageView!
    private var productPrice: UILabel!
    private var productDiscountPrice: UILabel!
    private var progress: UIActivityIndicatorView!
    private var bookMarkBt: UIButton!
    private var addButton: UIButton!
    private var adicionar: UIButton!
    
    /* Product reference */
    private var product: Product?
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    init( frame: CGRect, product: Product, ctrl: UIViewController) {
        
        var frm = frame
        self.product = product
        super.init(frame: frm)

        /* Image */
        frm.origin.y = 0 /* center of the view */
        productImage = UIImageView(frame: frm)
        productImage.contentMode = .ScaleToFill
        productImage.setNeedsDisplay()
        
        addSubview(productImage)

        /* Register observer, we need to known when the image was downloaded */
        productImage.addObserver(self, forKeyPath: "image",
            options: NSKeyValueObservingOptions.New, context: nil)
  
        /* Progress, use the center of the view */
        let progressPos = CGPoint(x: frm.width/2, y: frm.height/2)
        progress = UIActivityIndicatorView()
        progress.center = progressPos
        progress.activityIndicatorViewStyle = .Gray
        progress.startAnimating()
        
        addSubview(progress)
        
        /* Frame Price Constraints:
        *   ScrollView
        *  ------------------
        * |            |
        * |            0
        * |   |------------
        * |-0-| Frame Price
        * |   |____________
        */
        
        let categxAxisPos = CGFloat(0)
        let categTopConstraints = CGFloat(0)
        let categWidth = CGFloat(60)
        let categHeight = CGFloat(60)
        let categSize = CGRect(x: categxAxisPos, y: categTopConstraints, width: categWidth, height: categHeight)
        
        lineImage = UIImageView(frame: categSize)
        lineImage.contentMode = .ScaleAspectFit
        
        addSubview(lineImage)
        
        /* Frame Price Constraints:
        * | ScrollView
        * |     ____________
        * |-16-|
        * |    | Frame Price
        * |    |____________
        * |            |
        * |            16
        * |            |
        * -------------------
        */
        
        let labelxAxisPos = CGFloat(16)
        let bottonConstraint = CGFloat(16)
        let labelWidth = CGFloat(120)
        let labelHeight = CGFloat(24)
        let labelyAxisPos = (frame.height - labelHeight - bottonConstraint)
        let labelSize = CGRect(x: labelxAxisPos, y: labelyAxisPos, width: labelWidth, height: labelHeight)

        
        productPrice = UILabel(frame: labelSize)
        productPrice.font = UIFont(name: "Lato-Regular", size: 20)
        productPrice.textAlignment = NSTextAlignment.Left
        productPrice.textColor = UIColor(white: 1, alpha: 1)
        productPrice.backgroundColor = UIColor(patternImage: UIImage(named: "bluebutton")!)
        addSubview(productPrice)

        let labelDiscountSize = CGRect(x: labelxAxisPos, y: labelyAxisPos-labelHeight-8, width: 120, height: labelHeight)
        productDiscountPrice = UILabel(frame: labelDiscountSize)
        productDiscountPrice.font = UIFont(name: "Lato-Regular", size: 15)
        productDiscountPrice.textAlignment = NSTextAlignment.Left
        productDiscountPrice.textColor = UIColor.whiteColor()
        productDiscountPrice.backgroundColor = UIColor.blackColor()
        addSubview(productDiscountPrice)
        
        /* Frame BookMark Constraints:
        *  ScrollView
        *------------------------------------
        *             |                      |
        *             0                      |
        *     ________|______                |
        *                    |               |
        *      Frame BookMark|-(-width-16)-  |
        *     _______________|               |
        */
        
        let bookMarkWidth = CGFloat(25)
        let bookMarkHeight = bookMarkWidth
        let bookMarkSize = CGSize(width: bookMarkWidth, height: bookMarkHeight)
        let bookMarkxAxisPos = ((frame.width) - bookMarkWidth - 16)
        let bookMarkPos = CGPoint(x: bookMarkxAxisPos, y: 16)
        let bookMarkAreaSize = CGRect(origin: bookMarkPos, size: (bookMarkSize))
        
        bookMarkBt = UIButton(frame: bookMarkAreaSize)
        bookMarkBt.addTarget(ctrl, action: #selector(ViewController.bookMarkAdd(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        bookMarkBt.setBackgroundImage(UIImage(named: "star"), forState: UIControlState.Normal)
        bookMarkBt.setBackgroundImage(UIImage(named: "starFilled"), forState: UIControlState.Selected)
        
        addSubview(bookMarkBt)
        
        let addButtonWidth = CGFloat(102)
        let addButtonHeight = CGFloat(27)
        let addButtonSize = CGSize(width: addButtonWidth, height: addButtonHeight)
        let addButtonxAxisPos = ((frame.width) - addButtonWidth - 16)
        let addButtonyAxisPos = (frame.height - addButtonHeight - bottonConstraint)
        let addButtonPos = CGPoint(x: addButtonxAxisPos, y: addButtonyAxisPos)
        let addButtonAreaSize = CGRect(origin: addButtonPos, size: (addButtonSize))
        
        addButton = UIButton(frame: addButtonAreaSize)
        addButton.addTarget(ctrl, action: #selector(ViewController.addButtonAction(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        addButton.setBackgroundImage(UIImage(named: "bluebutton"), forState: UIControlState.Normal)
        addButton.setBackgroundImage(UIImage(named: "greenbutton"), forState: UIControlState.Selected)
        addButton.setTitle("Adicionado", forState: .Selected)
        addButton.setTitle("Adicionar", forState: .Normal)
        addButton.titleLabel!.font = UIFont(name: "Lato-Regular", size: 20)
        
        addSubview(addButton)
    }
    
    deinit {
        productImage.removeObserver(self, forKeyPath: "image")
    }
    
    /* KVO for imageview */
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "image" {
            if let imgView = object as? UIImageView {
                if imgView.image != nil {
                    progress.stopAnimating()
                } else {
                    progress.startAnimating()
                }
            }
        }
    }
    
    func getProduct() -> Product {
        return product!
    }
    
    func setProduct(pd: Product) {
        product! = pd
    }
    
    func getProductImageView() -> UIImageView {
        return productImage!
    }
    
    func setProductImageView(img: UIImageView) {
        productImage = img
    }
    
    func getProductLineImageView() -> UIImageView {
        return lineImage!
    }

    func setProductPrice(price: Float) {
        
        productDiscountPrice.hidden = true
        productPrice.text = String.localizedStringWithFormat("  R$ %.2f  ", price)
        productPrice.sizeToFit()
        
        productPrice.backgroundColor = UIColor(patternImage: UIImage(named: "pricebg")!)
        productPrice.layer.masksToBounds = true
        productPrice.layer.cornerRadius = 10.0
    }
    
    func setProductDiscountPrice(price: Float, discount: Float) {
        
        let discountFormatted = String.localizedStringWithFormat("  R$ %.2f  ", price)

        let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: "  \(discountFormatted)  ")
        attributeString.addAttribute(NSStrikethroughStyleAttributeName, value: 2, range: NSMakeRange(0, attributeString.length))

        productDiscountPrice.hidden = false
        productDiscountPrice.attributedText = attributeString
        productDiscountPrice.sizeToFit()
        
        productDiscountPrice.layer.masksToBounds = true
        productDiscountPrice.layer.cornerRadius = 10.0
        
        productPrice.text = String.localizedStringWithFormat("  R$ %.2f  ", discount)
        productPrice.sizeToFit()
        
        productPrice.backgroundColor = UIColor(patternImage: UIImage(named: "pricebg")!)
        productPrice.layer.masksToBounds = true
        productPrice.layer.cornerRadius = 10.0
    }
    
    func setBookMarksSelected(state: Bool) {
        bookMarkBt.selected = state
    }
    
    func setAddSelected(state: Bool) {
        addButton.selected = state
    }
    
}
