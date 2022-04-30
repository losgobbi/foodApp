//
//  ViewController.swift
//  SushiD
//
//  Created by Leandro Silveira on 17/02/15.
//  Copyright (c) 2015 Hagen. All rights reserved.
//

import UIKit
import CoreData

/* Protocol between View/Car Controller used to update badge icon */
protocol UpdateBadgeDelegate {
    func setBadgeIcon()
}

class ViewController: UIViewController, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, DataLineDelegate {
    
    /* Outlets */
    @IBOutlet weak var productName: UILabel!
    @IBOutlet weak var productDesc: UITextView!
    @IBOutlet weak var progressBar: UIActivityIndicatorView!
    @IBOutlet weak var txtProgress: UILabel!
    @IBOutlet weak var scrollMenu: UIScrollView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var retryButton: UIButton!
    
    /* Model information */
    var scrollContent: [Product]?
    
    /* Api reference */
    var api = FoodApp.sharedInstance
    
    /* Coredata context */
    private var moc: NSManagedObjectContext?
    
    /* General control */
    private var line = 0
    private var lineHasChanged = false
    var popup = PopupAlertView()
    var runningIpad = isIpad()

    /* Recycle control */
    var recycler = ScrollRecycler()
    private var previousPage: CGFloat!

    /* Delegates */
    var badgeDelegate: UpdateBadgeDelegate? = nil
    
    /* fetching data retry count */
    private var retries = 0
    
    @IBAction func retryAction(sender: UIButton) {
        retryButton.enabled = false
        retryButton.hidden = true
        retries = 0
        self.unloadData()
    }
    
    /* Load data for the first time */
    override func viewDidLoad() {
        /* core data context */
        moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        api.setManagedContext(moc!)
        
        /* notifications for this viewcontroller */
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(ViewController.dataReady(_:)), name: FoodAppNotifications.DataReady.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.bookMarksDidChangeContent(_:)), name: CtrNotifications.BkTableContentChanged.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.carDidChangeContent(_:)), name: CtrNotifications.CarTableContentChanged.rawValue, object: nil)
        
        /* visual */
        retryButton.hidden = true
        progressBar.startAnimating()
        
        /* procedures and notifications to load data */
        self.loadData()
        
        /* init delegates */
        let barViewControllers = self.tabBarController!.viewControllers
        let filterController = barViewControllers![filterControllerIndex] as! FilterViewController
        filterController.setDelegate(self)
        
        let navController = barViewControllers![carControllerIndex] as! UINavigationController
        let carController = navController.viewControllers[0] as! CarTableViewController
        setBadgeDelegate(carController)
    }
    
    func loadData() {
        previousPage = 0
        retryButton.hidden = true
        productName.hidden = true
        productDesc.hidden = true
        scrollMenu.hidden = true
        collectionView.hidden = true

        txtProgress.text = "Carregando cardápio, por favor aguarde."
        txtProgress.font = UIFont(name: "Lato-LightItalic", size: 20)
        progressBar.hidden = false
        
        /* fetch data */
        api.fetchInitialData()
        scrollContent = [Product]()
    }
    
    func unloadData() {
        previousPage = 0
        
        /* core data context */
        api.eraseManagedContext()
        
        productName.hidden = false
        productDesc.hidden = false
        scrollMenu.hidden = false
        collectionView.hidden = false
        
        txtProgress.text = "Aguarde..."
        txtProgress.font = UIFont(name: "Lato-LightItalic", size: 20)
        
        self.loadData()
    }

    override func viewWillAppear(animated: Bool) {
        if (runningIpad == true) {
            if (lineHasChanged == true) {
                lineHasChanged = false
            }
            return
        }
        if (lineHasChanged == true) {
            lineHasChanged = false
            reloadScrollMenu()
        }
    }
    
    /* Data is ready, we can go on */
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
        self.showObjects()
    }

    func showObjects() {
        progressBar.hidden = true
        txtProgress.hidden = true
        retryButton.hidden = true
        
        /* show objects */
        self.tabBarController?.tabBar.hidden = false
        productName.hidden = false
        productDesc.hidden = false
        scrollMenu.hidden = false
        collectionView.hidden = false
        
        /* recover user */
        do {
            let (logged, login, _) = try api.userIsLogged()
            if login != nil && logged {
                /* Cross check user */
                let _ = try api.getUser(login!)
                api.userAuthentication(login!)
            }
        } catch let error as NSError {
            print("showObjects(): Cant recover user logged. Error = \(error)")
            /* Expires user if we cant recover it */
            try! api.userUnauthenticate()
        }
        
        /* prepare scroll */
        if !runningIpad {
            prepareScrollMenu()
        } else {
            prepareCollection()
        }

        /* update badge */
        badgeDelegate?.setBadgeIcon()
    }
    
    /* The product was removed/added from car/fav */
    func bookMarksDidChangeContent(notification: NSNotification) {
        if let userInfo = notification.userInfo?["ProductChanged"] {
            let pd = userInfo as! Product
            
            /* if this pd is in a visible page, flush both buttons */
            if let pdView = getSubViewFromProduct(pd) {
                do {
                    pdView.setBookMarksSelected(try api.isProductInBookMarks(pd))
                    pdView.setAddSelected(try api.isProductInCar(pd))
                } catch let error as NSError {
                    print("bookMarksDidChangeContent(): Unable to check contains during BkChanged. Error = \(error)")
                }
            }
        }
        
        /* update badge because the NFR may has not been loaded */
        badgeDelegate?.setBadgeIcon()
    }
    
    func carDidChangeContent(notification: NSNotification) {
        do {
            if let userInfo = notification.userInfo?["ProductChanged"] {
                let pd = userInfo as! Product
                if let pdView = getSubViewFromProduct(pd) {
                    pdView.setAddSelected(try api.isProductInCar(pd))
                }
            } else {
                /* wildcard was signed, update the first visible page */
                let page = recycler.recGetCurrentPage()
                if let pdView = getVisibleProductView(page) {
                    let pd = scrollContent![page]
                    pdView.setAddSelected(try api.isProductInCar(pd))
                }
            }
        } catch let error as NSError {
            print("carDidChangeContent(): Unable to update PdView during CarChanged. Error = \(error)")
        }
    }

    
    /* Load scroll menu with numberOfElements */
    func loadDataForScrollMenu(numberOfElements: Int) -> Int {
        do {
            if (line == 0) {
                scrollContent = try api.getInitialProducts(numberOfElements)
            } else {
                let initialLine = try api.getLine(line)
                scrollContent = try api.getProductList(initialLine)
            }
        } catch let error as NSError {
            print("loadDataForScrollMenu(): Unable to loadScrollMenu, line = \(line). Error = \(error)")
            return 0
        }
        
        return scrollContent!.count
    }
    
    /* delegate functions */
    func userDidEnterLine(info: Int) {
        if line == info {
            lineHasChanged = false
            return
        }
        
        lineHasChanged = true
        line = info
        
        if (runningIpad == true) {
            resetCollectionView()
        } else {
            resetScrollMenu()
        }
    }
    
    /* set badge delegate */
    func setBadgeDelegate(vc: CarTableViewController) {
        badgeDelegate = vc
    }

    func addButtonAction(sender: UIButton!) {
        let pd = scrollContent![recycler.recGetCurrentPage()]
        sender.selected = !sender.selected
        
        do {
            if (sender.selected == true) {
                try api.addProductToUserCar(pd)
            } else {
                try api.remProductFromUserCar(pd)
            }
        } catch let error as NSError {
            print("addButtonAction(): Unable to add/rem Product = \(pd.id) in Car. Error = \(error)")
        }

        badgeDelegate?.setBadgeIcon()
        
        let transitionOptions = UIViewAnimationOptions.TransitionFlipFromBottom
        UIView.transitionWithView(sender, duration: 0.5, options: transitionOptions, animations: {
            }, completion: { finished in
        })
    }
    
    func bookMarkAdd(sender: UIButton!) {
        let pd = scrollContent![recycler.recGetCurrentPage()]
        sender.selected = !sender.selected;
        
        do {
            if (sender.selected == true) {
                try api.addUserBookMark(pd)
            } else {
                try api.remUserBookMark(pd)
            }
        } catch let error as NSError {
            print("bookMarkAdd(): Unable to add/rem Product = \(pd.id) in Bk. Error = \(error)")
        }
        let transitionOptions = UIViewAnimationOptions.TransitionFlipFromRight
        UIView.transitionWithView(sender, duration: 0.5, options: transitionOptions, animations: {
            }, completion: { finished in
        })
    }
    
    /* General functions */

    /* Get Pdviews only */
    func getProductSubViews() -> [ProductView] {
        var pdviews = [ProductView]()
        for i in 0..<scrollMenu!.subviews.count {
            /* bypass hidden subviews */
            if let pdView = scrollMenu!.subviews[i] as? ProductView {
                pdviews.append(pdView)
            }
        }
        return pdviews
    }
    
    func getSubViewFromProduct(pd: Product) -> ProductView? {
        let pdsViews = getProductSubViews()
        for i in 0..<pdsViews.count {
            if pd == pdsViews[i].getProduct() {
                return pdsViews[i]
            }
        }
        
        /* not found */
        return nil
    }
    
    /* Get visible ProductView at page */
    func getVisibleProductView(page: Int) -> ProductView? {
        let pdsViews = getProductSubViews()
        for i in 0..<pdsViews.count {
            let currentPage = pdsViews[i].frame.origin.x/scrollMenu.frame.width
            if Int(currentPage) == page {
                return pdsViews[i]
            }
        }
        
        /* should not happen */
        return nil
    }
    
    /*
     * Restart progress bar for Product's imageview. 
     * For lineimageview, erase image.
     * Update info according to the new product.
     */
    func flushProductView(pdView: ProductView, transientImg: Bool) {
        let pd = pdView.getProduct()
        let pdViewPage = Int(pdView.frame.origin.x/scrollMenu.frame.width)
        
        /* Check if there is a image in the product */
        if let _ = pd.productImage.image as NSData? {
            /* reset image, we need to start progress bar */
            pdView.getProductImageView().image = nil
            pdView.getProductLineImageView().image = nil
        } else {
            /* check for a transient image */
            if let _ = pdView.getProductImageView().image {
                if transientImg {
                    pdView.getProductImageView().image = nil
                    pdView.getProductLineImageView().image = nil
                }
            }
        }
        
        /* update product before the didend delegate */

        let pdUpdate = scrollContent![pdViewPage]
        pdView.setProduct(pdUpdate)
        
        if (pdUpdate.discount == true) {
            pdView.setProductDiscountPrice(pdUpdate.price, discount: pdUpdate.discountPrice)
        } else {
            pdView.setProductPrice(pdUpdate.price)
        }
        
        do {
            pdView.setBookMarksSelected(try api.isProductInBookMarks(pdUpdate))
            pdView.setAddSelected(try api.isProductInCar(pdUpdate))
        } catch let error as NSError {
            print("flushProductView(): Unable to flush PdView Product = \(pd.id) transientImg = \(transientImg). Error = \(error)")
        }
    }
    
    func getPreviousPage() -> CGFloat {
        return previousPage
    }
    
    func setPreviousPage(page: CGFloat) {
        previousPage = page
    }
    
    func getScrollContentCount() -> Int {
        return scrollContent!.count
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "productSegue" {
            guard let pdController = segue.destinationViewController as?
                ProductViewController else {
                    return
            }
            
            guard let cell = sender as? UICollectionViewCell else {
                return
            }
            
            pdController.cell = cell as? ProductCollectionViewCell
        }
    }
}
