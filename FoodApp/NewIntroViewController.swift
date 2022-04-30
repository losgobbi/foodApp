//
//  NewCollectionView.swift
//  FoodApp
//
//  Created by Leandro Silveira on 02/07/16.
//  Copyright © 2016 Hagen. All rights reserved.
//

import UIKit
import CoreData

class NewIntroViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDataSource, UITableViewDelegate{
    
    /* Outlets */
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionHeight: NSLayoutConstraint!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var txtProgress: UILabel!
    @IBOutlet weak var progressBar: UIActivityIndicatorView!
    @IBOutlet weak var retryButton: UIButton!
    @IBOutlet weak var promoçoesLabel: UILabel!
    @IBOutlet weak var promocoesHeight: NSLayoutConstraint!
    @IBOutlet weak var topViewHeight: NSLayoutConstraint!
    
    /* Control */
    private var api = FoodApp.sharedInstance
    private var collectionContentPromo: [Product]?
    private var collectionContentFilter: [Product]?
    private var lines = [Line]()
    private var tabHeight: CGFloat = 0.0
    
    /* Delegates */
    private var badgeDelegate: UpdateBadgeDelegate? = nil

    /* fetching data retry count */
    private var retries = 0
    
    /* Coredata context */
    private var moc: NSManagedObjectContext?
    
    @IBAction func retryAction(sender: AnyObject) {
        retryButton.enabled = false
        retryButton.hidden = true
        retries = 0
        self.unloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        topViewHeight.constant = UIScreen.mainScreen().bounds.height
    }
    
    override func viewDidLoad() {
        let backView = UIView(frame: CGRectMake(0, 0, nvLogoWidth, nvLogoHeight))
        let titleImageView = UIImageView(image: UIImage(named: "logo-foodApp.png"))
        
        titleImageView.frame = CGRectMake(0, nvStatusBarHeight, nvLogoWidth, nvLogoHeight)
        backView.addSubview(titleImageView)
        self.navigationItem.titleView = backView
        self.navigationController?.navigationBar.layoutIfNeeded()
        self.automaticallyAdjustsScrollViewInsets = false

        moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        api.setManagedContext(moc!)
        
        /* notifications for this viewcontroller */
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.bookMarksDidChangeContent(_:)), name: CtrNotifications.BkTableContentChanged.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(self.dataReady(_:)), name: FoodAppNotifications.DataReady.rawValue, object: nil)
        
        collectionHeight.constant = (((UIScreen.mainScreen().bounds.width*0.4)/167)*112)+85+8
        topViewHeight.constant = UIScreen.mainScreen().bounds.height
        
        tableView.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.New, context: nil)
        
        /* visual */
        retryButton.hidden = true
        progressBar.startAnimating()
        
        /* init delegates */
        let barViewControllers = self.tabBarController!.viewControllers
        let navController = barViewControllers![carControllerIndex] as! UINavigationController
        let carController = navController.viewControllers[0] as! CarTableViewController
        setBadgeDelegate(carController)
        
        /* procedures and notifications to load data */
        self.loadData()
        
        if isIpad() {
            promoçoesLabel.font = UIFont(name: "Lato-LightItalic", size: 46)
        }
        
        tabHeight = (self.tabBarController?.tabBar.frame.height)!
        self.tabBarController?.tabBar.frame = CGRect(x: (self.tabBarController?.tabBar.frame.origin.x)!,
                                                     y: (self.tabBarController?.tabBar.frame.origin.y)! + tabHeight,
                                                     width: (self.tabBarController?.tabBar.frame.width)!,
                                                     height: (self.tabBarController?.tabBar.frame.height)!)
        
        
    }

    /* set badge delegate */
    func setBadgeDelegate(vc: CarTableViewController) {
        badgeDelegate = vc
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return (collectionContentPromo!.count)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let screenWidth = collectionView.frame.width
        var screenHeight = collectionView.frame.height
        screenHeight = (((UIScreen.mainScreen().bounds.width*0.4)/167)*112)+85
        return CGSize(width: screenWidth*0.4, height: screenHeight)
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("newcellcollection", forIndexPath: indexPath)
        let cellPd = cell as! NewCollectionCell
        var product: Product?
        var discount: Float
        
        product = collectionContentPromo![indexPath.row]
        
        discount = -(100*product!.discountPrice/product!.price-100)
        cellPd.productDiscountPercent.text = String.localizedStringWithFormat("  ﹣%.0f%%", discount)
        cellPd.productDiscountPercent.text = cellPd.productDiscountPercent.text! + String.localizedStringWithFormat(" ")
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
        
        cellPd.layer.shouldRasterize = true;
        cellPd.layer.rasterizationScale = UIScreen.mainScreen().scale;
        cellPd.productName.text = product!.name
        cellPd.productDiscount.text = String.localizedStringWithFormat("  R$ %.2f  ", product!.price)
        if isIpad() {
            cellPd.productName.font = UIFont(name: "Lato-Light", size: 20)
            cellPd.productDiscount.font = UIFont(name: "Lato-Regular", size: 20)
        }
        
        cellPd.layoutIfNeeded()
        
        NSNotificationCenter.defaultCenter().postNotificationName(FoodAppNotifications.ImageNotification.rawValue, object: self, userInfo: ["imageView": cellPd.productImage, "product": product!])
        
        return cellPd
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lines.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let disclosureImage = UIImage(named: "disclosure")
        let disclosureView = UIImageView(image: disclosureImage)
        cell.accessoryView = disclosureView
        cell.backgroundColor = cell.contentView.backgroundColor;
        
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("newFilterTableCell", forIndexPath: indexPath)
        let cellPd = cell as! NewTableViewFilterCell
        let line = lines[indexPath.row]
        
        
        
        cellPd.filterName.text = line.name
        NSNotificationCenter.defaultCenter().postNotificationName(FoodAppNotifications.ImageNotification.rawValue,
             object: self, userInfo: ["imageView": cellPd.filterImage, "line": line])
        
        return cellPd
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UIScreen.mainScreen().bounds.height*0.12
    }
    
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        do {
            let line = try api.getLine(Int(lines[indexPath.row].id))
            collectionContentFilter = try api.getProductList(line)
        } catch {
            print("willSelectRowAtIndexPath(): failed to get line")
        }

        return indexPath
    }
    
    /* The product was removed/added from car/fav */
    func bookMarksDidChangeContent(notification: NSNotification) {        
        /* update badge because the NFR may has not been loaded */
        badgeDelegate?.setBadgeIcon()
    }
    
    func dataReady(notification: NSNotification) {
        if let userInfo = notification.userInfo as? [String: AnyObject] {
            if let jsonError = userInfo["jsonError"] as? NSError {
                /* stop loading */
                progressBar.hidden = true
                txtProgress.font = UIFont(name: "Lato-LightItalic", size: 20)
                txtProgress.text = "Ainda carregando dados. (\(jsonError.code))."

                /* retry */
                retries += 1
                print("dataReady(): Error during fetch. Retries:(\(retries)) err:(\(jsonError.code)).")
                txtProgress.text = "Não foi possível carregar o cardápio. Por favor, verifique sua conexão com a internet ou tente mais tarde. (\(jsonError.code))."
                retryButton.hidden = false
                retryButton.enabled = true
                progressBar.hidden = true

                if (retries > maxfetchInitialRetries) {
                    return
                }
                
                self.unloadData()
                return
            }
        }
        
        showObjects()
    }
    
    func loadData() {
        scrollView.hidden = true
        collectionView.hidden = true
        retryButton.hidden = true

        txtProgress.text = "Carregando cardápio, por favor aguarde."
        txtProgress.font = UIFont(name: "Lato-LightItalic", size: 20)
        progressBar.hidden = false
        
        /* fetch data */
        api.fetchInitialData()
        collectionContentPromo = [Product]()
        collectionContentFilter = [Product]()
    }
    
    func unloadData() {
        /* core data context */
        api.eraseManagedContext()
        
        txtProgress.text = "Aguarde..."
        txtProgress.font = UIFont(name: "Lato-LightItalic", size: 20)
        
        self.loadData()
    }
    
    func showObjects() {
        retryButton.hidden = true
        progressBar.hidden = true
        txtProgress.hidden = true
        
        /* show objects */
        self.tabBarController?.tabBar.frame = CGRect(x: (self.tabBarController?.tabBar.frame.origin.x)!,
                                                     y: (self.tabBarController?.tabBar.frame.origin.y)! - tabHeight,
                                                     width: (self.tabBarController?.tabBar.frame.width)!,
                                                     height: (self.tabBarController?.tabBar.frame.height)!)
        scrollView.hidden = false
        collectionView.hidden = false
        
        /* recover user */
        do {
            let (logged, login, _) = try api.userIsLogged()
            if login != nil && logged {
                /* Cross check user */
                let _ = try api.getUser(login!)
                api.userAuthentication(login!)
            } else if logged == false {
                /* There is no user logged, clean all cars since its a fresh start */
                api.removeAllCars()
            }
        } catch let error as NSError {
            print("showObjects(): Cant recover user logged. Error = \(error)")
            /* Expires user if we cant recover it */
            try! api.userUnauthenticate()
        }
        
        /* build data */
        do {
            lines = try api.getLines()
        } catch let error as NSError {
            print("dataReady(): Unable to get lines. Error = \(error)")
        }
        
        tableView.reloadData()
        prepareCollection()
        
        /* update badge */
        badgeDelegate?.setBadgeIcon()
    }
    
    func prepareCollection() {
        let nElements = loadDataForScrollMenu(scrollInitialNumber)
        var insertIndexPath = [NSIndexPath]()
        for i in 0..<nElements {
            insertIndexPath.append(NSIndexPath(forItem: i, inSection: 0))
        }
        collectionView.insertItemsAtIndexPaths(insertIndexPath)
    }
    
    func loadDataForScrollMenu(numberOfElements: Int) -> Int {
        do {
            collectionContentPromo = try api.getProductPromoList()
        } catch let error as NSError {
            print("loadDataForScrollMenu(): Unable to loadScrollMenu. Error = \(error)")
            return 0
        }
        
        return collectionContentPromo!.count
    }
    
    /* KVO for imageview */
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "contentSize" {
            if let tableView = object as? UITableView {
                topViewHeight.constant = tableView.contentSize.height + collectionHeight.constant + 10 + promocoesHeight.constant
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "filterSegue" {
            guard let pdController = segue.destinationViewController as?
                NewProductViewController else {
                    return
            }
            
            pdController.collectionContent = collectionContentFilter
        }
        
        if segue.identifier == "promoProductSegue" {
            guard let pdDetail = segue.destinationViewController as?
                NewProductDetailViewController else {
                    return
            }
            
            let cell = sender as! NewCollectionCell
            let indexPath = self.collectionView.indexPathForCell(cell)
            pdDetail.product = collectionContentPromo![indexPath!.row]
        }
    }
}
