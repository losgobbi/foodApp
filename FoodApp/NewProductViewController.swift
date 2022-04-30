//
//  NewProductViewController.swift
//  FoodApp
//
//  Created by Leandro Silveira on 25/07/16.
//  Copyright © 2016 Hagen. All rights reserved.
//


import UIKit
import CoreData

class NewProductViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    /* Outlets */
    @IBOutlet weak var collectionView: UICollectionView!
    
    /* Control */
    private var indexPath: NSIndexPath?
    var collectionContent: [Product]?
    
    override func viewDidLoad() {
        /* nav appearance */
        let backView = UIView(frame: CGRectMake(0, 0, nvLogoWidth, nvLogoHeight))
        let titleImageView = UIImageView(image: UIImage(named: "logo-foodApp.png"))
        titleImageView.frame = CGRectMake(0, nvStatusBarHeight, nvLogoWidth, nvLogoHeight)
        backView.addSubview(titleImageView)
        self.navigationItem.titleView = backView
        self.navigationController?.navigationBar.layoutIfNeeded()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Voltar",
            style: UIBarButtonItemStyle.Plain, target: nil, action: nil)

        self.tabBarController?.tabBar.hidden = false
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (collectionContent == nil) {
            return 0
        } else {
            return (collectionContent!.count)
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let screenWidth = collectionView.frame.width
        
        return CGSize(width: screenWidth*0.5 - 16 - 8, height: (((screenWidth*0.5 - 16 - 8)/167)*112)+85)
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("newcellFilter", forIndexPath: indexPath)
        let cellPd = cell as! ProductDetailCell
        
        var product: Product?
        
        
        product = collectionContent![indexPath.row]
        
        
        cellPd.layer.shouldRasterize = true;
        cellPd.layer.rasterizationScale = UIScreen.mainScreen().scale;
        cellPd.productName.text = product!.name
        cellPd.productPrice.text = String.localizedStringWithFormat("R$ %.2f", product!.price)
        cellPd.productDiscountPercent.hidden = true
        
        if isIpad() {
            cellPd.productName.font = UIFont(name: "Lato-Light", size: 20)
            cellPd.productPrice.font = UIFont(name: "Lato-Regular", size: 20)
        }
        
        if (product?.discount == true) {
            var discount: Float
            
            discount = -(100*product!.discountPrice/product!.price-100)
            cellPd.productDiscountPercent.text = String.localizedStringWithFormat("﹣%.0f%%", discount)
            
            
            cellPd.productDiscountPercent.hidden = false
            cellPd.productPrice.text = String.localizedStringWithFormat("R$ %.2f", product!.discountPrice)
            switch product!.productLine.name {
            case "Light":
                cellPd.productDiscountPercent.backgroundColor = UIColor(patternImage: UIImage(named: "DiscountGreen")!)
            case "Tradicional":
                cellPd.productDiscountPercent.backgroundColor = UIColor(patternImage: UIImage(named: "DiscountOrange")!)
            case "Executiva":
                cellPd.productDiscountPercent.backgroundColor = UIColor(patternImage: UIImage(named: "DiscountBlue")!)
            case "Sopas":
                cellPd.productDiscountPercent.backgroundColor = UIColor(patternImage: UIImage(named: "DiscountYellow")!)
            case "Natal":
                cellPd.productDiscountPercent.backgroundColor = UIColor(patternImage: UIImage(named: "DiscountRed")!)
            case "Fitness":
                cellPd.productDiscountPercent.backgroundColor = UIColor(patternImage: UIImage(named: "DiscountRed")!)
            default:
                cellPd.productDiscountPercent.backgroundColor = UIColor(patternImage: UIImage(named: "DiscountOrange")!)
                break
            }
        }
        
        
        
        cellPd.layoutIfNeeded()
        
        NSNotificationCenter.defaultCenter().postNotificationName(FoodAppNotifications.ImageNotification.rawValue, object: self, userInfo: ["imageView": cellPd.productImage, "product": product!])
        
        return cellPd
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "detailProductSegue" {
            guard let pdController = segue.destinationViewController as?
                NewProductDetailViewController else {
                    return
            }
            
            segue.destinationViewController.hidesBottomBarWhenPushed = true
            
            let cell = sender as! ProductDetailCell
            let indexPath = self.collectionView.indexPathForCell(cell)
            
            pdController.product = collectionContent![indexPath!.row]
        }
    }
}
