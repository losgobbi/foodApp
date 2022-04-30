//
//  ViewController+Ipad.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 5/11/16.
//  Copyright © 2016 Hagen. All rights reserved.
//
//  Ipad Controller for ViewController
//

import UIKit

extension ViewController {
    
    
    func resetCollectionView() {
        self.scrollContent?.removeAll()
        self.loadDataForScrollMenu(scrollInitialNumber)
        collectionView.reloadData()
    }

    func prepareCollection() {
        let nElements = loadDataForScrollMenu(scrollInitialNumber)
        var insertIndexPath = [NSIndexPath]()
        for i in 0..<nElements {
            insertIndexPath.append(NSIndexPath(forItem: i, inSection: 0))
        }
        collectionView.insertItemsAtIndexPaths(insertIndexPath)
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (scrollContent?.count == 0) {
            return 0
        } else {
            return (scrollContent!.count)
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let screenWidth = collectionView.frame.width
        let screenHeight = collectionView.frame.height
        return CGSize(width: screenWidth/2 - 8, height: screenHeight/3 - 24)
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cellCollection", forIndexPath: indexPath)
        let cellPd = cell as! ProductCollectionViewCell
        var product: Product?
        
        cell.layer.shouldRasterize = true;
        cell.layer.rasterizationScale = UIScreen.mainScreen().scale;
        
        product = scrollContent![indexPath.row]
        cellPd.product = product;
        cellPd.badgeDelegate = badgeDelegate
        cellPd.productName.text = product!.name
        cellPd.productName.sizeToFit()
        
        print(cellPd.productName.text)
        
        cellPd.productDesc = product!.desc
        cellPd.productPrice = String.localizedStringWithFormat("  R$ %.2f  ", product!.price)
        
        NSNotificationCenter.defaultCenter().postNotificationName(FoodAppNotifications.ImageNotification.rawValue, object: self, userInfo: ["imageView": cellPd.productImage, "product": product!])
    
        NSNotificationCenter.defaultCenter().postNotificationName(FoodAppNotifications.ImageNotification.rawValue, object: self, userInfo: ["imageView": cellPd.productLine, "line": product!.productLine])
        
        /* keep tag value for cancel purpose */
        if indexPath.row >= collectionVisibleCellNumber + 2 {
            return cell
        }
        cellPd.productImage.tag = indexPath.row
        return cell
    }
}