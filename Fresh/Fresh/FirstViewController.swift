//  FirstViewController.swift
//  Fresh

import UIKit
import MapKit
import Parse
import Bolts

class FirstViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UISearchBarDelegate, UIPopoverPresentationControllerDelegate {
    
    // Location
    let locationManager: CLLocationManager = CLLocationManager()
    var userLocation: CLLocation!
    var mapChangedFromUserInteraction = false
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var viewGetLocation: UIView!
    @IBOutlet weak var getLocationButton: UIButton!
    
    // Custom pins
    var smallCustomPin = SmallPin()

    // Profile
    @IBOutlet weak var profileNavBarButton: UIBarButtonItem!
    
    // Search bar controller
    var searchController: UISearchController!
    var searchResultsTableViewController: UITableViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Change the color of the navigation bar
        navigationController!.navigationBar.barTintColor = UIColor(red: 131/255, green: 192/255, blue: 101/255, alpha: 1)
        
        // Location
        getUserLocation()

        // Custom pins
        smallCustomPin = NSBundle.mainBundle().loadNibNamed("SmallPin", owner: self, options: nil)[0] as! SmallPin
        smallCustomPin.layer.cornerRadius = 6
        
        // Properties of the getLocation button view
        viewGetLocation.alpha = 0.9
        viewGetLocation.layer.cornerRadius = 5
        
        // Search bar controller
        searchResultsTableViewController = UITableViewController()
        searchController = UISearchController(searchResultsController: searchResultsTableViewController)
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.delegate = self
        self.navigationItem.titleView = searchController.searchBar
        searchController.searchBar.placeholder = "Search for farmers or products..."
        
        // Check if the user is logged in - if s/he isn't, ask to log in or sign up
        if PFUser.currentUser() == nil {
            ask()
        }
        
        // Check if thee are new custom pins or if some of them have been deleted
        retrieveData()
        
        // Display custom pins on the map
        addCustomPins()
    }
    
    /************************************ PARSE **********************************/
    
    // Fetch the objects from the server, so we can check if some objects have been deleted/newly added
    func retrieveData() {
        let query = PFQuery(className: "Products")
        query.findObjectsInBackgroundWithBlock {
            (objects: [PFObject]?, error: NSError?) -> Void in
            print("Successfully retrieved \(objects!.count) objects in retrieveData().")
            if error == nil && objects != nil {
                for myObject in objects! {
                    print("Dealing with object \(myObject.objectId!) right now.")
                    // If an object doesn't have the latitude and/or the longitude, then assign them to it
                    if myObject["Latitude"] == nil || myObject["Longitude"] == nil || myObject["Latitude"] as! Float == 0 || myObject["Longitude"] as! Float == 0 {
                        print("Non ho trovato il valore latitude per l'oggetto \(myObject.objectId)")
                        self.convertLocationToCoordinates(myObject)
                    }
                    // Save the objects locally, so the app can show pins even if there is no data connection the next time the user opens the app
                    myObject.pinInBackground()
                }
            } else {
                print("I couldn't load your objects. Error: \(error)")
            }
        }
    }
    
    // Converts the address given by the user to actual coordinates (latitude, longitude)
    // Once the coordinates have been found, the objects is saved to the server
    func convertLocationToCoordinates(myObject: PFObject) {
        let address = myObject["Location"]
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address! as! String, completionHandler: { (placemarks, error) -> Void in
            if let placemark = placemarks?[0] as CLPlacemark! {
                myObject["Latitude"] = Float(placemark.location!.coordinate.latitude)
                myObject["Longitude"] = Float(placemark.location!.coordinate.longitude)
                myObject.saveInBackgroundWithBlock {
                    (success: Bool, error: NSError?) -> Void in
                    if (error == nil) {
                        print("Error while saving the object after converting the address to coordinates.")
                    }
                }
            }
        })
    }
    
    func showAllSavedObjectsLocalDatastore() {
        let query = PFQuery(className:"Products")
        query.fromLocalDatastore()
        query.findObjectsInBackgroundWithBlock {
            (objects: [PFObject]?, error: NSError?) -> Void in
            print("Successfully retrieved \(objects!.count) objects in the local datastore in showAllSavedObjectsLocalDatastore()")
            if error == nil {
                
            } else {
                print("Error while retrieving the objects saved locally.")
            }
        }
    }
    
    /*********************************** LOCATION ********************************/
    
    // Change the image of the "getLocation" button when the user taps on it
    @IBAction func tapOnGetLocation(sender: AnyObject) {
        self.getLocationButton.setImage(UIImage(named: "request1"), forState: UIControlState.Normal)
        getUserLocation()
    }
    
//    func mapViewRegionDidChangeFromUserInteraction() -> Bool {
//        let view = self.mapView.subviews[0]
//        //  Look through gesture recognizers to determine whether this region change is from user interaction
//        if let gestureRecognizers = view.gestureRecognizers {
//            for recognizer in gestureRecognizers {
//                if (recognizer.state == UIGestureRecognizerState.Began || recognizer.state == UIGestureRecognizerState.Ended) {
//                    return true
//                }
//            }
//        }
//        return false
//    }
    
    //Detect panning on a map
//    func mapView(mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
//        mapChangedFromUserInteraction = mapViewRegionDidChangeFromUserInteraction()
//        if (mapChangedFromUserInteraction) {
//            self.getLocationButton.setImage(UIImage(named: "request0"), forState: UIControlState.Normal)
//        }
//    }
    
    func getUserLocation() {
        locationManager.delegate = self // instantiate the CLLocationManager object
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            locationManager.requestAlwaysAuthorization()
        }
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        
        self.locationManager.startUpdatingLocation() // continuously send the application a stream of location data
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        mapView.setCenterCoordinate(newLocation.coordinate, animated: true)
        let viewRegion = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 6000, 6000)
        mapView.setRegion(viewRegion, animated: false)
        
        manager.stopUpdatingLocation()
    }
    
    /******************************* CUSTOM PINS *********************************/
    
    func addCustomPins() {
        let myCustomPin = MKPointAnnotation()
        let query = PFQuery(className:"Products")
        query.fromLocalDatastore()
        query.findObjectsInBackgroundWithBlock {
            (objects: [PFObject]?, error: NSError?) -> Void in
            print("Successfully retrieved \(objects!.count) objects in the local datastore in addCustomPins()")
            if error == nil {
                for object in objects! {
                    let coordinates = CLLocationCoordinate2DMake(object["Latitude"] as! Double, object["Longitude"] as! Double)
                    myCustomPin.coordinate = coordinates
                    self.mapView.addAnnotation(myCustomPin)
                }
            } else {
                print("Error while retrieving the objects saved locally.")
                let coordinates = CLLocationCoordinate2DMake(0, 0)
                myCustomPin.coordinate = coordinates
            }
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return mapView.dequeueReusableAnnotationViewWithIdentifier("")
        } else {
            let annotationView = MKAnnotationView(frame: CGRectMake(0, 0, 33, 36))
            // scroll through objects saved locally
            
            let query = PFQuery(className:"Products")
            query.fromLocalDatastore()
            query.findObjectsInBackgroundWithBlock {
                (objects: [PFObject]?, error: NSError?) -> Void in
                print("Successfully retrieved \(objects!.count) objects in the local datastore in ViewForAnnotation()")
                if error == nil {
                    //for object in objects! {
                        //self.myView.labelTitle.text = object["Title"] as? String
                        //self.myView.labelPrice.text = object["Price"] as? String
                    //}
                } else {
                    print("Error while retrieving the objects saved locally.")
                }
            }
            
            //myView.labelTitle.text = "Hello!"
            
            annotationView.centerOffset = CGPointMake(0, -25)
            annotationView.addSubview(smallCustomPin)
            annotationView.enabled = true
            annotationView.canShowCallout = false
            annotationView.annotation = annotation
            return annotationView
        }
    }
    
//    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
//        print("didAddAnnotationViews()")
//        
//        var i = -1;
//        for view in views {
//            i++;
//            let mkView = view as! MKAnnotationView
//            if view.annotation is MKUserLocation {
//                continue;
//            }
//            
//            // Check if current annotation is inside visible map rect, else go to next one
//            let point:MKMapPoint  =  MKMapPointForCoordinate(mkView.annotation!.coordinate);
//            if (!MKMapRectContainsPoint(self.mapView.visibleMapRect, point)) {
//                continue;
//            }
//            
//            let endFrame:CGRect = mkView.frame;
//            
//            // Move annotation out of view
//            mkView.frame = CGRectMake(mkView.frame.origin.x, mkView.frame.origin.y - self.view.frame.size.height, mkView.frame.size.width, mkView.frame.size.height);
//            
//            // Animate drop
//            let delay = 0.03 * Double(i)
//            UIView.animateWithDuration(0.5, delay: delay, options: UIViewAnimationOptions.CurveEaseIn, animations:{() in
//                mkView.frame = endFrame
//                // Animate squash
//                }, completion:{(Bool) in
//                    UIView.animateWithDuration(0.05, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations:{() in
//                        //mkView.transform = CGAffineTransformMakeScale(1.0, 0.6)
//                        
//                        }, completion: {(Bool) in
//                            UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations:{() in
//                                mkView.transform = CGAffineTransformIdentity
//                                }, completion: nil)
//                    })
//                    
//            })
//        }
//    }
    
    /*****************************************************************************/
    
    @IBAction func addPopover(sender: UIBarButtonItem) {
//        let profileOptions = UIAlertController()
//        let currentUser = PFUser.currentUser()
//        
//        if (currentUser == nil) {
//            profileOptions.addAction(UIAlertAction(title: "Sign up", style: UIAlertActionStyle.Default, handler: {(action: UIAlertAction!) -> Void in
//                self.signUp()
//            }))
//            
//            profileOptions.addAction(UIAlertAction(title: "Log in", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction!) -> Void in
//                self.signIn()
//            }))
//        } else {
//            profileOptions.addAction(UIAlertAction(title: "Sign out", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction!) -> Void in
//                PFUser.logOut()
//            }))
//            
//            if (isFarmer == 0) {
//                profileOptions.addAction(UIAlertAction(title: "Switch to Farmer", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction!) -> Void in
//                    let query = PFQuery(className: "_User")
//                    query.getObjectInBackgroundWithId((self.objectID)!) {
//                        (farmer: PFObject?, error: NSError?) -> Void in
//                        if error == nil && farmer != nil {
//                            self.isFarmer = (farmer?.objectForKey("farmer") as! Int)
//                            if (self.isFarmer == 1) {
//                                print("This user is a farmer!")
//                            } else {
//                                print("This user is not a farmer.")
//                                self.switchToFarmer()
//                            }
//                        } else {
//                            print("Something is not working with retrieving the farmer status: \(error)")
//                        }
//                    }
//                    
//                }))
//            }
//        }
//        
//        profileOptions.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Destructive, handler: nil))
//        
//        // Display the action sheet
//        profileOptions.popoverPresentationController?.barButtonItem = profileNavBarButton
//        presentViewController(profileOptions, animated: true, completion: nil)
    }
    
    func ask() {
//        let askSheetController: UIAlertController = UIAlertController(title: "Welcome to Fresh!", message: "Create a Fresh account or log into an existing one to connect with farmers around the world.", preferredStyle: .Alert)
//        let signupAction: UIAlertAction = UIAlertAction(title: "Sign up", style: .Default) { action -> Void in
//            self.signUp()
//        }
//        askSheetController.addAction(signupAction)
//        
//        let loginAction: UIAlertAction = UIAlertAction(title: "Log in", style: .Default) { action -> Void in
//            self.signIn()
//        }
//        askSheetController.addAction(loginAction)
//        
//        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
//        askSheetController.addAction(cancelAction)
//        
//        presentViewController(askSheetController, animated: true, completion: nil)
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
    
//    func signIn() {
//        var emailTextField: UITextField?
//        var passwordTextField: UITextField?
//        
//        let signupSheetController: UIAlertController = UIAlertController(title: "Sign in to Fresh", message: "Log into your Fresh account to see what farmers are sellingr.", preferredStyle: .Alert)
//        
//        let signupAction: UIAlertAction = UIAlertAction(title: "Sign in", style: .Default) { action -> Void in
//            self.userEmail = emailTextField!.text!
//            self.userPassword = passwordTextField!.text!
//            print(self.userEmail)
//            print(self.userPassword)
//        }
//        signupSheetController.addAction(signupAction)
//        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in }
//        signupSheetController.addAction(cancelAction)
//        
//        signupSheetController.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
//            textField.textColor = UIColor.blackColor()
//            textField.placeholder = "Email"
//            textField.secureTextEntry = false
//            emailTextField = textField
//        })
//        
//        signupSheetController.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
//            textField.textColor = UIColor.blackColor()
//            textField.placeholder = "Password"
//            textField.secureTextEntry = true
//            passwordTextField = textField
//        })
//        
//        // Create the user
//        let user = PFUser()
//        user.email = userEmail
//        userEmail = userEmail.lowercaseString // ensure the e-mail is lowercase
//        user.username = userEmail
//        user.password = userPassword
//        let userLogin = PFUser.currentUser()
//        
//        // TODO: FIX THIS
//        PFUser.logInWithUsernameInBackground(userEmail, password: userPassword) {
//            (user: PFUser?, error: NSError?) -> Void in
//            if userLogin != nil {
//                self.objectID = userLogin?.objectId
//            } else {
//                print("Login failed!")
//            }
//        }
//        
//        if (PFUser.currentUser() == nil) {
//            presentViewController(signupSheetController, animated: true, completion: nil)
//        } else {
//            print("User successfully authenticated!")
//        }
//    }
    
    // MARK: Add Product page
    func switchToFarmer() {
        let btnName: UIButton = UIButton()
        btnName.frame = CGRectMake(0, 0, 22, 22)
        btnName.setImage(UIImage(named: "plus"), forState: .Normal)
        btnName.addTarget(self, action: Selector("goToAddProduct"), forControlEvents: .TouchUpInside)
        
        //.... Set Right/Left Bar Button item
        let rightBarButton: UIBarButtonItem = UIBarButtonItem()
        rightBarButton.customView = btnName
        self.navigationItem.rightBarButtonItem = rightBarButton
    }
    
    func goToAddProduct() {
        let storyboard : UIStoryboard = UIStoryboard(name: "New", bundle: nil)
        let vc : ProductsTableViewController = storyboard.instantiateViewControllerWithIdentifier("products") as! ProductsTableViewController
        let navigationController = UINavigationController(rootViewController: vc)
        self.presentViewController(navigationController, animated: true, completion: nil)
    }
    
    // MARK: Search bar stuff
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
    }
    
    // MARK: Other methods
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
}