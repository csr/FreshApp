//  Fresh
//  FirstViewController.swift

import UIKit
import MapKit
import Parse
import Bolts

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UISearchBarDelegate, UIPopoverPresentationControllerDelegate {
    
    let locationManager = CLLocationManager()
    let userLocation = CLLocation()
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var getLocationView: UIView!
    @IBOutlet weak var getLocationButton: UIButton!
    @IBOutlet weak var profileNavigationBarButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpLocationManager()
        updateUserLocation()
        addSearchBarToNavigationBar()
        addCustomPinsToMap()
    }
    
    func setUpLocationManager() {
        locationManager.delegate = self
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            locationManager.requestAlwaysAuthorization()
        }
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
    }
    
    @IBAction func updateUserLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func addSearchBarToNavigationBar() {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search for local markets, farmers or products..."
        self.navigationItem.titleView = searchBar
    }
    
    @IBAction func changeStateImageOfGetLocationButton(sender: AnyObject) {
        self.getLocationButton.setImage(UIImage(named: "request1"), forState: UIControlState.Normal)
    }
    
    func mapViewRegionDidChangeFromUserInteraction() -> Bool {
        let view = self.mapView.subviews[0]
        if let gestureRecognizers = view.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if (recognizer.state == UIGestureRecognizerState.Began || recognizer.state == UIGestureRecognizerState.Ended) {
                    return true
                }
            }
        }
        return false
    }
    
    var mapChangedFromUserInteraction = false
    func mapView(mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        mapChangedFromUserInteraction = mapViewRegionDidChangeFromUserInteraction()
        if (mapChangedFromUserInteraction) {
            self.getLocationButton.setImage(UIImage(named: "request0"), forState: UIControlState.Normal)
        }
    }
    
    var notFirstZoom = false
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        mapView.setCenterCoordinate(newLocation.coordinate, animated: true)
        let viewRegion = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 6000, 6000)
        mapView.setRegion(viewRegion, animated: notFirstZoom)
        notFirstZoom = true
        manager.stopUpdatingLocation()
    }
    
    func addCustomPinsToMap() {
        let myCustomPin = MKPointAnnotation()
        let query = PFQuery(className:"Products")
        query.fromLocalDatastore()
        query.findObjectsInBackgroundWithBlock {
            (objects: [PFObject]?, error: NSError?) -> Void in
            print("Successfully retrieved \(objects!.count) objects in the local datastore in addCustomPins()")
            if objects != nil {
                for object in objects! {
                    let coordinates = CLLocationCoordinate2DMake(object["Latitude"] as! Double, object["Longitude"] as! Double)
                    myCustomPin.coordinate = coordinates
                    self.mapView.addAnnotation(myCustomPin)
                }
            } else if error != nil {
                print(error)
                myCustomPin.coordinate = CLLocationCoordinate2DMake(0, 0)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
}