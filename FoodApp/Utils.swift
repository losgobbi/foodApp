//
//  Utils.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 5/1/15.
//  Copyright (c) 2015 Hagen. All rights reserved.
//
//  Utils functions and classes
//

import Foundation
import UIKit

func solidImage(color: UIColor, size: CGSize = CGSize(width: 1,height: 1)) -> UIImage {
    let rect = CGRectMake(0, 0, size.width, size.height)
    UIGraphicsBeginImageContextWithOptions(size, false, 0)
    color.setFill()
    UIRectFill(rect)
    let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
}

/* Replace 'src' by 'dst' string in array 'textArray' */
func replace_char(inout textArray: [String], token_source src: String,
    token_dst dst: String) {
        var pos = 0
        for txt in textArray {
            textArray[pos] = txt.stringByReplacingOccurrencesOfString(src,
                withString: dst, options: NSStringCompareOptions.LiteralSearch,
                range: nil)
            pos += 1
        }
}

/* Replace multiples 'srcs' in the array */
func replace_multiplechars(inout textArray: [String],
    token_source src: [String], token_dst dst: String) {
        for token in src {
            replace_char(&textArray, token_source: token, token_dst: dst)
        }
}

/* Get random number between 0..<upperLimit */
func getRandomNumber(upperLimit: Int) -> Int {
    return (Int)(arc4random_uniform((UInt32)(upperLimit)))
}

/* Format date to 'Full String' */
func timeToStr(date: NSDate) -> String {
    let fmt = NSDateFormatter.localizedStringFromDate(date,
        dateStyle: .FullStyle, timeStyle: .FullStyle)
    return fmt
}

/* Convert hex to uicolor */
func UIColorFromHex(rgbValue: Int, alpha: Double = 1.0) -> UIColor {
    let red = CGFloat((rgbValue & 0xFF0000) >> 16)/256.0
    let green = CGFloat((rgbValue & 0xFF00) >> 8)/256.0
    let blue = CGFloat(rgbValue & 0xFF)/256.0
    
    return UIColor(red: red, green: green, blue: blue, alpha: CGFloat(alpha))
}

func formatDate2string(date: NSDate, format: String) -> String {
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = format
    dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") /* QA1480 */
    let dateStr = dateFormatter.stringFromDate(date)
    return dateStr
}

func formatTime2string(date: NSDate, format: String) -> String {
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = format
    dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") /* QA1480 */
    let timeStr = dateFormatter.stringFromDate(date)
    return timeStr
}
