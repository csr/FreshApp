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

    var smallCustomPin = SmallPin()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpLocationManager()
        updateUserLocation()

        addSearchBarToNavigationBar()
        smallCustomPin = SmallPin.loadNib()
        checkIfObjectsHaveCoordinates()
        addCustomPinsToMap()
        
        if PFUser.currentUser() == nil {
            askLogInOrSignUp()
        }
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
    
    func checkIfObjectsHaveCoordinates() {
        PFQuery(className: "Products").findObjectsInBackgroundWithBlock {
            (objects: [PFObject]?, error: NSError?) in
            if objects != nil {
                for object in objects! {
                    if object["Latitude"] == nil || object["Longitude"] == nil {
                        self.convertObjectLocationToCoordinates(object)
                    }
                }
            } else if error != nil {
                print(error)
            }
        }
    }
    
    func addSearchBarToNavigationBar() {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search for farmers or products..."
        self.navigationItem.titleView = searchBar
    }
    
    func convertObjectLocationToCoordinates(myObject: PFObject) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(myObject["Location"] as! String, completionHandler: { (placemarks, error) -> Void in
            if let placemark = placemarks?[0] as CLPlacemark! {
                myObject["Latitude"] = Float(placemark.location!.coordinate.latitude)
                myObject["Longitude"] = Float(placemark.location!.coordinate.longitude)
                myObject.saveInBackgroundWithBlock {
                    (success: Bool, error: NSError?) -> Void in
                    if (error != nil) {
                        print(error)
                    }
                }
            }
        })
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
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return mapView.dequeueReusableAnnotationViewWithIdentifier("")
        } else {
            let annotationView = MKAnnotationView(frame: CGRectMake(0, 0, 100, 45))
            let query = PFQuery(className:"Products")
            query.fromLocalDatastore()
            query.findObjectsInBackgroundWithBlock {
                (objects: [PFObject]?, error: NSError?) -> Void in
                print("Successfully retrieved \(objects!.count) objects in the local datastore in ViewForAnnotation()")
                if objects != nil {
                    for object in objects! {
                        self.smallCustomPin.labelTitle.text = object["Title"] as? String
                    }
                } else if error != nil {
                    print(error)
                }
            }
            
            annotationView.centerOffset = CGPointMake(0, -50)
            annotationView.backgroundColor = UIColor.whiteColor()
            annotationView.layer.cornerRadius = 6
            annotationView.addSubview(smallCustomPin)
            annotationView.enabled = true
            annotationView.canShowCallout = false
            annotationView.annotation = annotation
            return annotationView
        }
    }
    
    func tapOnSmallCustomPin() {
        print("Tap on small custom pin!")
    }
    
    @IBAction func showProfileSettings (sender: UIBarButtonItem) {
        let profileOptions = UIAlertController()
        let currentUser = PFUser.currentUser()
        
        if (currentUser == nil) {
            profileOptions.addAction(UIAlertAction(title: "Sign up", style: UIAlertActionStyle.Default, handler: {(action: UIAlertAction!) -> Void in
                self.signUp()
            }))
            
            profileOptions.addAction(UIAlertAction(title: "Log in", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction!) -> Void in
                self.signIn()
            }))
        } else {
            profileOptions.addAction(UIAlertAction(title: "Sign out", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction!) -> Void in
                PFUser.logOut()
            }))
        }
        profileOptions.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Destructive, handler: nil))
        
        // Display the action sheet
        profileOptions.popoverPresentationController?.barButtonItem = profileNavigationBarButton
        presentViewController(profileOptions, animated: true, completion: nil)
    }
    
    func askLogInOrSignUp() {
        let askSheetController: UIAlertController = UIAlertController(title: "Welcome to Fresh!", message: "Create a Fresh account or log into an existing one to connect with farmers around the world.", preferredStyle: .Alert)
        let signupAction: UIAlertAction = UIAlertAction(title: "Sign up", style: .Default) { action -> Void in
            self.signUp()
        }
        askSheetController.addAction(signupAction)
        
        let loginAction: UIAlertAction = UIAlertAction(title: "Log in", style: .Default) { action -> Void in
            self.signIn()
        }
        askSheetController.addAction(loginAction)
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        askSheetController.addAction(cancelAction)
        
        presentViewController(askSheetController, animated: true, completion: nil)
    }
    
    var userEmail = ""
    var userPassword = ""
    func signUp() {
        var emailTextField: UITextField?
        var passwordTextField: UITextField?
        
        let signupSheetController: UIAlertController = UIAlertController(title: "Sign up to Fresh", message: "Create an account to connect with farmers around the world and fill your fridge with healthy food.", preferredStyle: .Alert)
        
        let signupAction: UIAlertAction = UIAlertAction(title: "Sign up", style: .Default) { action -> Void in
            self.userEmail = emailTextField!.text!
            self.userPassword = passwordTextField!.text!
            print(self.userEmail)
            print(self.userPassword)
            
            // Create the user
            let user = PFUser()
            self.userEmail = self.userEmail.lowercaseString
            user.email = self.userEmail
            user.username = self.userEmail
            user.password = self.userPassword
            
            user.signUpInBackgroundWithBlock {
                (succeeded: Bool, error: NSError?) -> Void in
                if error == nil {
                    print("Success!")
                } else {
                    print("Signing up failed.")
                }
            }
        }
        signupSheetController.addAction(signupAction)
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in }
        signupSheetController.addAction(cancelAction)
        
        signupSheetController.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.textColor = UIColor.blackColor()
            textField.placeholder = "Email"
            textField.secureTextEntry = false
            emailTextField = textField
        })
        
        signupSheetController.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.textColor = UIColor.blackColor()
            textField.placeholder = "Password"
            textField.secureTextEntry = true
            passwordTextField = textField
        })
        
        presentViewController(signupSheetController, animated: true, completion: nil)
    }
    
    func signIn() {
        var emailTextField: UITextField?
        var passwordTextField: UITextField?
        
        let signupSheetController: UIAlertController = UIAlertController(title: "Sign in to Fresh", message: "Log into your Fresh account to see what farmers are selling.", preferredStyle: .Alert)
        
        let signupAction: UIAlertAction = UIAlertAction(title: "Sign in", style: .Default) { action -> Void in
            self.userEmail = emailTextField!.text!
            self.userPassword = passwordTextField!.text!
            print(self.userEmail)
            print(self.userPassword)
        }
        signupSheetController.addAction(signupAction)
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in }
        signupSheetController.addAction(cancelAction)
        
        signupSheetController.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.textColor = UIColor.blackColor()
            textField.placeholder = "Email"
            textField.secureTextEntry = false
            emailTextField = textField
        })
        
        signupSheetController.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.textColor = UIColor.blackColor()
            textField.placeholder = "Password"
            textField.secureTextEntry = true
            passwordTextField = textField
        })
        
        let user = PFUser()
        user.email = userEmail
        userEmail = userEmail.lowercaseString // ensure the email is lowercase
        user.username = userEmail
        user.password = userPassword
        let userLogin = PFUser.currentUser()
        
//        PFUser.logInWithUsernameInBackground(userEmail, password: userPassword) {
//            (user: PFUser?, error: NSError?) -> Void in
//        }
        
        if (PFUser.currentUser() == nil) {
            presentViewController(signupSheetController, animated: true, completion: nil)
        } else {
            print("User successfully authenticated!")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
}