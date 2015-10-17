import UIKit
import MapKit
import Parse
import Bolts

class FirstViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UISearchBarDelegate, UIPopoverPresentationControllerDelegate {
    
    // Location Objects
    let locationManager: CLLocationManager = CLLocationManager()
    var userLocation: CLLocation!
    var mapChangedFromUserInteraction = false
    
    // UI elements
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var getLocationButton: UIButton!
    @IBOutlet weak var profileNavBarButton: UIBarButtonItem!
    @IBOutlet weak var viewGetLocation: UIView!
    @IBOutlet weak var viewSmallPin: UIView!
    @IBOutlet weak var labelSmallPinTitle: UILabel!
    @IBOutlet weak var labelSmallPinPrice: UILabel!
    
    var searchController:UISearchController!
    var searchResultsTableViewController:UITableViewController!
    var storePins:[CustomPin] = []
    var currentSelection:Int!
    
    // Parse class: User
    var isFarmer = 0
    var objectID: String! // ??
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Change NavigationBar color
        navigationController!.navigationBar.barTintColor = UIColor(red: 131/255, green: 192/255, blue: 101/255, alpha: 1)
        
        // Location
        mapView.showsUserLocation = true
        mapView.delegate = self
        self.getUserLocation(self)
        viewGetLocation.alpha = 0.9
        viewGetLocation.layer.cornerRadius = 5
        
        searchResultsTableViewController = UITableViewController()
        searchResultsTableViewController.view.backgroundColor = UIColor.whiteColor()
        searchController = UISearchController(searchResultsController: searchResultsTableViewController)
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.delegate = self
        self.navigationItem.titleView = searchController.searchBar
        searchController.searchBar.placeholder = "Search for farmers or products..."
        
        let userLogin = PFUser.currentUser()
        
        if userLogin == nil {
            ask()
        }
        
        signIn() // Try to authenticate the user
        retrieveData()
    }
    
    /************************************ PARSE **********************************/
    func retrieveData() {
        let query = PFQuery(className: "Products")
        query.findObjectsInBackgroundWithBlock {
            (objects: [PFObject]?, error: NSError?) -> Void in
            print("Successfully retrieved \(objects!.count) scores.")
            // Do something with the found objects
            if error == nil && objects != nil {
                for myObject in objects! {
                    print("Dealing with object \(myObject.objectId!) right now.")
                    if myObject["Latitude"] == nil || myObject["Longitude"] == nil {
                        print("Non ho trovato il valore latitude per l'oggetto \(myObject.objectId)")
                        self.convertLocationToCoordinates(myObject)
                    }
                    myObject.pinInBackground()
                }
            } else {
                print("I couldn't load your objects. Error: \(error)")
            }
        }
    }
    
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
                        print(error)
                    }
                }
            }
        })
    }
    /*****************************************************************************/
    
    // Check values in arrays of "Product" class
    @IBAction func tapOnGetLocation(sender: AnyObject) {
        self.getLocationButton.setImage(UIImage(named: "request1"), forState: UIControlState.Normal)
        getUserLocation(self)
    }
    
    private func mapViewRegionDidChangeFromUserInteraction() -> Bool {
        let view = self.mapView.subviews[0]
        //  Look through gesture recognizers to determine whether this region change is from user interaction
        if let gestureRecognizers = view.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if (recognizer.state == UIGestureRecognizerState.Began || recognizer.state == UIGestureRecognizerState.Ended) {
                    return true
                }
            }
        }
        return false
    }
    
    // Detect panning on a map
    func mapView(mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        mapChangedFromUserInteraction = mapViewRegionDidChangeFromUserInteraction()
        if (mapChangedFromUserInteraction) {
            self.getLocationButton.setImage(UIImage(named: "request0"), forState: UIControlState.Normal)
        }
    }
    
    func getUserLocation(sender: AnyObject) {
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
        mapView.setRegion(viewRegion, animated: true)
        
        manager.stopUpdatingLocation()
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return mapView.dequeueReusableAnnotationViewWithIdentifier("")
        } else {
            
            let annotationView = MKAnnotationView()
            annotationView.enabled = true
            annotationView.canShowCallout = false
            annotationView.addSubview(viewSmallPin)
            let coordinates = CLLocationCoordinate2D(latitude: 45.4626482, longitude: 9.0376472)
            let myAnnotation = CustomPin(title: "Hello", descr: "Hello", price: "Hello", coordinate: coordinates)
            annotationView.annotation = myAnnotation
            mapView.addAnnotation(myAnnotation)
            
            return annotationView
        }
    }
    
    @IBAction func addPopover(sender: UIBarButtonItem) {
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
            
            if (isFarmer == 0) {
                profileOptions.addAction(UIAlertAction(title: "Switch to Farmer", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction!) -> Void in
                    let query = PFQuery(className: "_User")
                    query.getObjectInBackgroundWithId((self.objectID)!) {
                        (farmer: PFObject?, error: NSError?) -> Void in
                        if error == nil && farmer != nil {
                            self.isFarmer = (farmer?.objectForKey("farmer") as! Int)
                            if (self.isFarmer == 1) {
                                print("This user is a farmer!")
                            } else {
                                print("This user is not a farmer.")
                                self.switchToFarmer()
                            }
                        } else {
                            print("Something is not working with retrieving the farmer status: \(error)")
                        }
                    }
                    
                }))
            }
        }
        
        profileOptions.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Destructive, handler: nil))
        
        // Display the action sheet
        profileOptions.popoverPresentationController?.barButtonItem = profileNavBarButton
        presentViewController(profileOptions, animated: true, completion: nil)
    }
    
    func ask() {
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
        
        let signupSheetController: UIAlertController = UIAlertController(title: "Sign in to Fresh", message: "Log into your Fresh account to see what farmers are sellingr.", preferredStyle: .Alert)
        
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
        
        // Create the user
        let user = PFUser()
        user.email = userEmail
        userEmail = userEmail.lowercaseString // ensure the e-mail is lowercase
        user.username = userEmail
        user.password = userPassword
        let userLogin = PFUser.currentUser()
        
        PFUser.logInWithUsernameInBackground(userEmail, password: userPassword) {
            (user: PFUser?, error: NSError?) -> Void in
            if userLogin != nil {
                self.objectID = userLogin?.objectId
            } else {
                print("Login failed!")
            }
        }
        
        if (PFUser.currentUser() == nil) {
            presentViewController(signupSheetController, animated: true, completion: nil)
        } else {
            print("User successfully authenticated!")
        }
    }
    
    // MARK: Search bar stuff
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
    }
    
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
    
    // MARK: Other methods
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
}

class CustomPin: NSObject, MKAnnotation {
    let title: String?
    let descr: String?
    let price: String?
    let coordinate: CLLocationCoordinate2D
    
    init(title: String, descr: String, price: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.descr = descr
        self.price = price
        self.coordinate = coordinate
        super.init()
    }
}