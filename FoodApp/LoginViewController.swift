//
//  LoginViewController.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 3/14/15.
//  Copyright (c) 2015 Hagen. All rights reserved.
//
//  Controller for Login View
//

import UIKit
import CoreData

class LoginViewController: UIViewController, UITextFieldDelegate {

    /* Outlets */
    @IBOutlet weak var loginFailedTxt: UILabel!
    @IBOutlet weak var loginBt: UIButton!
    @IBOutlet weak var loginTxt: UITextField!
    @IBOutlet weak var passTxt: UITextField!
    @IBOutlet weak var loginProgress: UIActivityIndicatorView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var newUserBt: UIButton!
    
    /* API */
    private var api = FoodApp.sharedInstance
    
    /* General stuff */
    private var popup = PopupAlertView()
    
    override func viewDidLoad() {
        let swipedown: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(LoginViewController.dismissKeyboard))
        swipedown.direction = UISwipeGestureRecognizerDirection.Down
        
        self.view.addGestureRecognizer(swipedown)
        
        let backView = UIView(frame: CGRectMake(0, 0, nvLogoWidth, nvLogoHeight))
        let titleImageView = UIImageView(image: UIImage(named: "logo-foodApp.png"))
        
        titleImageView.frame = CGRectMake(0, nvStatusBarHeight, nvLogoWidth, nvLogoHeight)
        backView.addSubview(titleImageView)
        self.navigationItem.titleView = backView
        self.navigationController?.navigationBar.layoutIfNeeded()
    }
    
    override func viewWillAppear(animated: Bool) {
        loginProgress.hidden = true
        progressLabel.hidden = true
        loginFailedTxt.hidden = true

        /* notifications for this viewcontroller */
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector:#selector(LoginViewController.loginFinished(_:)), name: FoodAppNotifications.LoginStatus.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector:#selector(LoginViewController.userSynched(_:)), name: FoodAppNotifications.UserSynchronized.rawValue, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        progressLabel.font = UIFont(name: "Lato-LightItalic", size: 20.0)
        loginTxt.font = UIFont(name: "Lato-LightItalic", size: 20.0)
        passTxt.font = UIFont(name: "Lato-LightItalic", size: 20.0)
        loginBt.titleLabel?.font = UIFont(name: "Lato-Light", size: 20.0)
        newUserBt.titleLabel?.font = UIFont(name: "Lato-LightItalic", size: 20.0)
        
        if (api.checkNetwork() != true) {
            popup.popupAlert(PopupMessages.NoInternet.Title, message: PopupMessages.NoInternet.Message, button: PopupMessages.NoInternet.Button, view: self)
            /* stop progress */
            loginProgress.hidden = true
            progressLabel.hidden = true
            loginBt.hidden = false
            return
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        dismissKeyboard()
        
        if (textField == self.loginTxt) {
            self.passTxt.becomeFirstResponder()
        }
        
        if (textField == self.passTxt) {
            loginAction(self.loginBt)
        }
        
        return true
    }
    
    func dismissKeyboard() {
        self.loginTxt.resignFirstResponder()
        self.passTxt.resignFirstResponder()
    }
    
    @IBAction func loginAction(sender: UIButton) {
        newUserBt.hidden = true
        loginBt.hidden = true
        loginProgress.hidden = false
        loginProgress.startAnimating()
        progressLabel.hidden = false

        if (api.checkNetwork() != true) {
            popup.popupAlert(PopupMessages.NoInternet.Title, message: PopupMessages.NoInternet.Message, button: PopupMessages.NoInternet.Button, view: self)
            /* stop progress */
            loginProgress.hidden = true
            progressLabel.hidden = true
            loginBt.hidden = false
            newUserBt.hidden = false
            return
        }
        
        /* start login process */
        api.validateLogin(loginTxt.text!, password: passTxt.text!)
    }
    
    /* notifications */
    func loginFinished(notification: NSNotification) {
        let userInfo = notification.userInfo as! [String: AnyObject]
        let loginStatus = userInfo["loginStatusHttp"] as! Int

        /* stop progress */
        loginProgress.hidden = true
        progressLabel.hidden = true
        loginBt.hidden = false
        
        switch loginStatus {
        case 200:
            if let token = userInfo["token"] as? String,
                let tokenExpired = userInfo["tokenExpiration"] as? String {
                    do {
                        /* create token */
                        try api.userAuthentication(loginTxt.text!,
                            token: token, expireDate: tokenExpired)
                        
                        /* create elements if we cant find them */
                        let user = try? api.getUser(self.loginTxt.text!)
                        if user == nil {
                            let newUser = try api.addUser()
                            let newAddress1 = api.addAddress()
                            
                            newUser?.login = self.loginTxt.text!
                            try api.addUserAddress((newUser?.login)!, address: newAddress1!)
                        }
                        
                        /* fetch user data */
                        try api.fetchUserData()
                    } catch let error as NSError {
                        print("loginFinished(): Unable to add token:'\(loginTxt.text!)' during login. Error = \(error)")
                    }
            }
        default:
            loginFailedAnimate()
            break;
        }
    }

    func loginFailedAnimate() {
        newUserBt.hidden = false
        loginBt.hidden = false
        loginProgress.hidden = true
        loginProgress.stopAnimating()
        progressLabel.hidden = true
        
        /* Login Failed Animation */
        loginFailedTxt.hidden = false
        loginFailedTxt.alpha = 1.0
        UIView.animateWithDuration(6.0, delay: 1.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.TransitionNone, animations: {
            self.loginFailedTxt.alpha = 0.0
            }, completion: nil)
    }
    
    func userSynched(notification: NSNotification) {
        let userInfo = notification.userInfo as! [String: AnyObject]
        let status = userInfo["status"] as! Int

        if (status != 200) {
            do {
                print("userSynched(): User data fetch failed, cleaning up")

                try api.removeAllAddresses()
                let user = try api.getUser()
                try api.removeUser((user?.login)!)
                try api.userUnauthenticate()
            } catch {
                print("userSynched(): failed removing user/addresses after unsuccessful user login.")
            }
            loginFailedAnimate()
            return;
        }
        
        self.performSegueWithIdentifier("LoginToOrderSegue", sender: self)
        self.navigationController?.popViewControllerAnimated(true)
    }
}
