//
//  PopupAlert.swift
//  FoodApp
//
//  Created by Lucas Tomazi on 5/2/15.
//  Copyright (c) 2015 Hagen. All rights reserved.
//

import UIKit

class PopupAlertView: UIView {
    func popupAlert(title: String, message: String, button: String, view: UIViewController) {
        if (NSClassFromString("UIAlertController") != nil) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: button, style: UIAlertActionStyle.Default, handler: nil))
            view.presentViewController(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertView()
            alert.title = title
            alert.message = message
            alert.addButtonWithTitle(button)
            alert.show()
        }
    }
}
