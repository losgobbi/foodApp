//
//  ViewController+Iphone.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 5/11/16.
//  Copyright © 2016 Hagen. All rights reserved.
//
//  Iphone Controller for ViewController
//

import UIKit

//UICollectionView inherits from UIScrollView, so be careful with the delegate methods

extension ViewController {
 
    func reloadScrollMenu() {
        var product: Product?
        let elements: Int
        var scrollElement = 0
        /* Load elements in the scroll */
        elements = loadDataForScrollMenu(scrollInitialNumber)
        
        /* scroll menu */
        for subview in scrollMenu.subviews {
            if !(subview is ProductView) {
                continue
            }
            
            let pdView = subview as! ProductView
            
            /* if we do not have the scrollInitialNumber, stop it. */
            if scrollElement == elements {
                break
            }
            
            product = scrollContent![scrollElement]
            
            if (product!.discount == true) {
                pdView.setProductDiscountPrice(product!.price, discount: product!.discountPrice)
            } else {
                pdView.setProductPrice(product!.price)
            }
            
            pdView.setProduct(product!)
            do {
                pdView.setBookMarksSelected(try api.isProductInBookMarks(product!))
                pdView.setAddSelected(try api.isProductInCar(product!))
            } catch let error as NSError {
                print("prepareScrollMenu(): Unable to update ProductView with pd = \(product!.id). Error = \(error)")
            }
            
            /* add to recycle's visible array */
            pdView.frame.origin.x = CGFloat(scrollElement)*pdView.frame.size.width
            scrollElement += 1
            /* add to recycle's visible array */
            flushProductView(pdView, transientImg: true)
            recycler.recAddPage(pdView)
        }
        
        scrollMenu.contentSize = CGSize(width: Int(scrollElement) * Int(scrollMenu.bounds.width) , height: 0)
        
        /* the first element on the first page */
        product = scrollContent![0]
        productName.text = product!.name
        productName.sizeToFit()
        productDesc.text = product!.desc
        productDesc.font = UIFont(name: "Lato-LightItalic", size: 20)
        
        if (api.checkNetwork() != true) {
            popup.popupAlert(PopupMessages.NoInternet.Title, message: PopupMessages.NoInternet.Message, button: PopupMessages.NoInternet.Button, view: self)
        }
        
        /* get the first image */
        let firstPdView = getProductSubViews().first!
        
        NSNotificationCenter.defaultCenter().postNotificationName(FoodAppNotifications.ImageNotification.rawValue,
            object: self, userInfo: ["imageView": firstPdView.getProductImageView(), "product": product!])
        
        NSNotificationCenter.defaultCenter().postNotificationName(FoodAppNotifications.ImageNotification.rawValue,
            object: self, userInfo: ["imageView": firstPdView.getProductLineImageView(), "lineProduct": product!.productLine])
        
        /* init recycler info */
        recycler.recInit(self, scrollView: scrollMenu, scrollSize: scrollContent!.count)
        recycler.recUpdateCurrentPage(0)
    }
    
    /* Reset scroll content */
    func resetScrollMenu() {
        
        scrollMenu.setContentOffset(CGPoint(x: 0.0, y: scrollMenu.contentOffset.y), animated: true)
        scrollContent!.removeAll()
        
        /* erase control data */
        recycler.recRestart()
    }
    
    func prepareScrollMenu() {
        var i: CGFloat = 0
        var product: Product?
        let elements: Int
        
        /* Load elements in the scroll */
        elements = loadDataForScrollMenu(scrollInitialNumber)
        
        /* scroll menu */
        for scrollElement in 0..<scrollInitialNumber {
            /* if we do not have the scrollInitialNumber, stop it. */
            if scrollElement == elements {
                break
            }
            product = scrollContent![scrollElement]
            let pdView = ProductView(frame: scrollMenu.bounds, product: product!, ctrl: self)
            pdView.frame.origin.x += i*pdView.frame.size.width
            
            if (product!.discount == true) {
                pdView.setProductDiscountPrice(product!.price, discount: product!.discountPrice)
            } else {
                pdView.setProductPrice(product!.price)
            }
            
            pdView.setProduct(product!)
            do {
                pdView.setBookMarksSelected(try api.isProductInBookMarks(product!))
                pdView.setAddSelected(try api.isProductInCar(product!))
            } catch let error as NSError {
                print("prepareScrollMenu(): Unable to update ProductView with pd = \(product!.id). Error = \(error)")
            }
            
            scrollMenu.addSubview(pdView)
            i++
            
            /* add to recycle's visible array */
            recycler.recAddPage(pdView)
        }
        
        scrollMenu.contentSize = CGSize(width: Int(i) * Int(scrollMenu.bounds.width) , height: 0)
        scrollMenu.bounces = true
        scrollMenu.pagingEnabled = true
        scrollMenu.showsHorizontalScrollIndicator = false
        
        /* the first element on the first page */
        product = scrollContent![0]
        productName.text = product!.name
        productName.sizeToFit()
        productDesc.text = product!.desc
        productDesc.font = UIFont(name: "Lato-LightItalic", size: 20)
        
        if (api.checkNetwork() != true) {
            popup.popupAlert(PopupMessages.NoInternet.Title, message: PopupMessages.NoInternet.Message, button: PopupMessages.NoInternet.Button, view: self)
        }
        
        /* get the first image */
        let firstPdView = getProductSubViews().first!
        
        NSNotificationCenter.defaultCenter().postNotificationName(FoodAppNotifications.ImageNotification.rawValue,
            object: self, userInfo: ["imageView": firstPdView.getProductImageView(), "product": product!])
        
        NSNotificationCenter.defaultCenter().postNotificationName(FoodAppNotifications.ImageNotification.rawValue,
            object: self, userInfo: ["imageView": firstPdView.getProductLineImageView(), "lineProduct": product!.productLine])
        
        /* init recycler info */
        recycler.recInit(self, scrollView: scrollMenu, scrollSize: scrollContent!.count)
        recycler.recUpdateCurrentPage(0)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if runningIpad {
            return
        }

        recycler.recDidScroll()
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if runningIpad {
            return
        }
        
        let conn = api.checkNetwork()
        if (conn != true) {
            popup.popupAlert(PopupMessages.NoInternet.Title, message: PopupMessages.NoInternet.Message, button: PopupMessages.NoInternet.Button, view: self)
        }
        
        let posX = (round(scrollView.contentOffset.x / scrollView.frame.width))
        let product = scrollContent![Int(posX)]
        
        /* update view content */
        productName.text = product.name
        productName.sizeToFit()
        productDesc.text = product.desc
        productDesc.font = UIFont(name: "Lato-LightItalic", size: 20)
        
        let pdView = getVisibleProductView(Int(posX))!
        
        /* force flush, maybe the connection was down */
        if Int(posX) != recycler.recGetCurrentPage() {
            flushProductView(pdView, transientImg: conn)
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(FoodAppNotifications.ImageNotification.rawValue,
            object: self, userInfo: ["imageView": pdView.getProductImageView(), "product": product])
        
        NSNotificationCenter.defaultCenter().postNotificationName(FoodAppNotifications.ImageNotification.rawValue,
            object: self, userInfo: ["imageView": pdView.getProductLineImageView(), "lineProduct": product.productLine])
        
        recycler.recDump()
    }
}