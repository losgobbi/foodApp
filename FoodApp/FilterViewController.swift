//
//  FilerViewController.swift
//  FoodApp
//
//  Created by Leandro Silveira on 26/04/15.
//  Copyright (c) 2015 Hagen. All rights reserved.
//

import UIKit

/* Protocol between Filter and View controllers */
protocol DataLineDelegate {
    func userDidEnterLine(info: Int)
}

class FilterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    /* Outlets */
    @IBOutlet weak var tableView: UITableView!
    
    /* Api reference */
    private var api = FoodApp.sharedInstance
    
    /* Model information */
    private var lines = [Line]()
    
    /* General control */
    private var popup = PopupAlertView()
    private var delegate: DataLineDelegate? = nil
    
    override func viewDidAppear(animated: Bool) {
        if (api.checkNetwork() != true) {
            popup.popupAlert(PopupMessages.NoInternet.Title, message: PopupMessages.NoInternet.Message, button: PopupMessages.NoInternet.Button, view: self)
            return
        }
        
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        tableView.tableFooterView = UIView()
        do {
            lines = try api.getLines()
        } catch let error as NSError {
            print("FilterViewController viewDidLoad(): Unable to get lines. Error = \(error)")
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("filtercell",
            forIndexPath: indexPath) as! FilterCell

        if (indexPath.row == lines.count) {
            cell.lineImage.image = UIImage(named: "AllCategories")
            cell.lineName.text = "Todas Linhas"
            cell.lineName.font.fontWithSize(10)
            cell.contentView.backgroundColor = UIColorFromHex(0xB99367, alpha: 0.5)
            return cell
        }
        
        let line = lines[indexPath.row]    
        cell.contentView.backgroundColor = UIColorFromHex(api.getLineColor(line), alpha: 0.4)
        cell.lineName.text = line.name
        cell.lineName.font.fontWithSize(10)
        NSNotificationCenter.defaultCenter().postNotificationName(FoodAppNotifications.ImageNotification.rawValue,
            object: self, userInfo: ["imageView": cell.lineImage, "line": line])
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lines.count+1
    }
    
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if (lines.count == indexPath.row) {
            delegate?.userDidEnterLine(0)
        } else {
            delegate?.userDidEnterLine(Int(lines[indexPath.row].id))
        }
        self.tabBarController?.selectedIndex = viewControllerIndex
        
        return indexPath
    }
    
    func getDelegate() -> DataLineDelegate? {
        return delegate
    }
    
    func setDelegate(vc: ViewController) {
        delegate = vc
    }
}
