//
//  ProductCollectionViewCell.swift
//  FoodApp
//
//  Created by Leandro Silveira on 05/04/16.
//  Copyright © 2016 Hagen. All rights reserved.
//

import UIKit
import Alamofire

class ProductCollectionViewCell: UICollectionViewCell {
    
    /* Outlets */
    @IBOutlet weak var productImage: UIImageView!
    @IBOutlet weak var productName: UILabel!
    @IBOutlet weak var productLine: UIImageView!
    
    /* View elements */
    var productDesc: String = ""
    var productPrice: String = ""
    var product: Product?
    var badgeDelegate: UpdateBadgeDelegate?
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
}
