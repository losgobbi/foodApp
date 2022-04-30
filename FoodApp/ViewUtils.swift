//
//  ViewUtils.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 10/5/15.
//  Copyright (c) 2015 Hagen. All rights reserved.
//
//  Utils for view classes
//

import UIKit

/* Shows a progress bar with a string inside the navigation bar titleview */
func showNavProgressBar(progressMsg: String, inout navtitleView: UIView?, inout viewIndicator: UIActivityIndicatorView?) {
    let progressBar = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
    progressBar.frame = CGRectMake(0, 0, 14, 14)
    progressBar.startAnimating()
    
    /* label */
    let titleLabel = UILabel()
    titleLabel.text = progressMsg
    let font = UIFont(name: "Lato-Light", size: 14.0)!
    titleLabel.font = font
    
    let thatFits = CGSizeMake(20.0, progressBar.frame.size.height)
    let fittingSize = titleLabel.sizeThatFits(thatFits)
    
    /* offset for label, after progress */
    let labelxPos = progressBar.frame.origin.x + progressBar.frame.size.width
    let spaceLabel: CGFloat = 5
    titleLabel.frame = CGRectMake(labelxPos + spaceLabel, 0, fittingSize.width, fittingSize.height)
    
    /* the whole title view (progress + label) */
    let viewX = progressBar.frame.size.width + titleLabel.frame.size.width
    let titleView = UIView(frame: CGRectMake(0, 0, viewX, progressBar.frame.size.height))
    
    /* add views to nav bar */
    titleView.addSubview(titleLabel)
    titleView.addSubview(progressBar)
    
    /* return info */
    navtitleView = titleView
    viewIndicator = progressBar
}

/* Add a toolbar with done button over keyboard */
func createToolBarWithDoneButton(vc: UIViewController, inout toolBarHeight: CGFloat) -> UIToolbar {
    let doneToolbar: UIToolbar = UIToolbar(frame: CGRectMake(0, 0, 0, 0))
    doneToolbar.backgroundColor = UIColor.whiteColor()
    
    let spaceBt = UIBarButtonItem(barButtonSystemItem:
        UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
    let doneBt = UIBarButtonItem(title: "OK", style: UIBarButtonItemStyle.Done,
        target: vc, action: Selector("doneButtonAction:"))
    
    let items = NSMutableArray()
    items.addObject(spaceBt)
    items.addObject(doneBt)
    
    doneToolbar.items = items as? [UIBarButtonItem]
    doneToolbar.sizeToFit()
    
    toolBarHeight = doneToolbar.frame.height
    return doneToolbar
}

/* Check if the presentingViewCtr will present a form sheet at full screen */
func viewIsFormSheetFullScreen(presentingViewCtr: UIViewController) -> Bool {

    /* XXX use size classes */
    let hclass = presentingViewCtr.traitCollection.horizontalSizeClass
    let vclass = presentingViewCtr.traitCollection.verticalSizeClass

    if hclass == UIUserInterfaceSizeClass.Regular && vclass == UIUserInterfaceSizeClass.Regular {
        /* its ipad, not full screen */
        return false
    }
    
    /* iphone is always at full screen */
    return true
}

func isIpad() -> Bool {
    return UIDevice.currentDevice().model.containsString("iPad")
}

func removeURLForbiddenChars(inout url: String) {
    let urlDiac = url.stringByFoldingWithOptions(.DiacriticInsensitiveSearch,
        locale: NSLocale.currentLocale())
    
    var urlSpace = [String]()
    urlSpace.append(urlDiac)
    replace_char(&urlSpace, token_source: " ", token_dst: "-")
    
    url = urlSpace.removeFirst()
}
