//
//  NewCollectionCell.swift
//  FoodApp
//
//  Created by Leandro Silveira on 02/07/16.
//  Copyright © 2016 Hagen. All rights reserved.
//

import UIKit

class NewCollectionCell: UICollectionViewCell {
    
    /* Outlets */
    @IBOutlet weak var productImage: UIImageView!
    @IBOutlet weak var productName: UILabel!
    @IBOutlet weak var productLine: UIImageView!
    @IBOutlet weak var productDiscount: UILabel!
    @IBOutlet weak var productDiscountPercent: UILabel!
    
    /* View elements */
    var productDesc: String = ""
    var product: Product?
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
}
