//
//  OrderCell.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 9/18/15.
//  Copyright (c) 2015 Hagen. All rights reserved.
//

import UIKit

class OrderCell: UITableViewCell {
    
    @IBOutlet weak var dateTxtField: UITextField!
    @IBOutlet weak var timeTxtField: UITextField!
    @IBOutlet weak var discountTxtField: UITextField!
    @IBOutlet weak var infoTxt: UITextView!
    @IBOutlet weak var discountProgress: UIActivityIndicatorView!
    @IBOutlet weak var discountBt: UIButton!
}
