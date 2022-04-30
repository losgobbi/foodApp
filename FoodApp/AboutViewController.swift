//
//  AboutViewController.swift
//  SushiTeste
//
//  Created by Leandro Silveira on 18/12/15.
//  Copyright © 2015 Hagen. All rights reserved.
//

import UIKit
import MapKit

class AboutViewController: UIViewController {

    @IBOutlet weak var mapViewIphone: MKMapView!
    @IBOutlet weak var Version: UILabel!
    
    let initialLocation = CLLocation(latitude: -30.021618, longitude: -51.195990)
    let annotation = MKPointAnnotation()
    let coord = CLLocationCoordinate2D(latitude: -30.021618, longitude: -51.195990)

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backView = UIView(frame: CGRectMake(0, 0, nvLogoWidth, nvLogoHeight))
        let titleImageView = UIImageView(image: UIImage(named: "logo-foodApp.png"))
        
        titleImageView.frame = CGRectMake(0, nvStatusBarHeight, nvLogoWidth, nvLogoHeight)
        backView.addSubview(titleImageView)
        self.navigationItem.titleView = backView
        self.navigationController?.navigationBar.layoutIfNeeded()
        self.automaticallyAdjustsScrollViewInsets = false


        
        Version.text = "Versão: " + appVersion()
        
        centerMapOnLocation(initialLocation)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    let regionRadius: CLLocationDistance = 100
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
            regionRadius * 2.0, regionRadius * 2.0)
        
        annotation.coordinate = coord
        
        mapViewIphone.setRegion(coordinateRegion, animated: true)
        mapViewIphone.addAnnotation(annotation)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
