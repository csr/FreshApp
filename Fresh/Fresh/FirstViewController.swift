import UIKit
import MapKit
import Parse
import Bolts

class FirstViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UISearchBarDelegate, UIPopoverPresentationControllerDelegate {
    
    // Location Objects
    let locationManager: CLLocationManager = CLLocationManager()
    var userLocation: CLLocation!
    
    // Flag variables
    var isFarmer = 0
    
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
    
    // Parse columns
    var titles = [String]()
    var descriptions = [String]()
    var prices = [String]()
    var latitudes = [Float]()
    var longitudes = [Float]()
    var objectID: String! // ??
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Change NavigationBar color
        navigationController!.navigationBar.barTintColor = UIColor(red: 131/255, green: 192/255, blue: 101/255, alpha: 1)
        
        // Location
        mapView.delegate = self
        mapView.showsUserLocation = true
        self.getUserLocation(self)
        viewGetLocation.alpha = 0.9
        viewGetLocation.layer.cornerRadius = 5
        
        searchResultsTableViewController = UITableViewController()
        searchResultsTableViewController.view.backgroundColor = UIColor.whiteColor()
        searchController = UISearchController(searchResultsController: searchResultsTableViewController)
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.delegate = self
        self.navigationItem.titleView = searchController.searchBar
        searchController.searchBar.placeholder = "Search for fresh products..."
        
        signIn() // Try to authenticate the user
    }
    
    @IBAction func tapOnGetLocation(sender: AnyObject) {
        UIView.animateWithDuration(0.4, animations: {
            self.getLocationButton.setImage(UIImage(named: "request1"), forState: UIControlState.Normal)
        })
        getUserLocation(self)
    }
    
    func getUserLocation(sender: AnyObject) {
        locationManager.delegate = self // instantiate the CLLocationManager object
        
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            locationManager.requestAlwaysAuthorization()
        }
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        self.locationManager.startUpdatingLocation()
        // continuously send the application a stream of location data
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        mapView.setCenterCoordinate(newLocation.coordinate, animated: true)
        let viewRegion = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 1300, 1300)
        mapView.setRegion(viewRegion, animated: true)
        
        manager.stopUpdatingLocation()
    }
    
    // Display the custom view
    func addStore(coordinate: CLLocationCoordinate2D) {
        print("addStore called!")

        var i = 0
        for title in titles {
            let storePin = CustomPin(title: title, descr: "", price: "", coordinate: coordinate)
            storePins.append(storePin)
            mapView.addAnnotation(storePin)
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKAnnotationView(frame: CGRectMake(0, 0, 186, 40))
        labelSmallPinPrice.text = "4.44/Kg"
        
        for title in titles {
            labelSmallPinTitle.text = title
        }
        
        for price in prices {
            labelSmallPinPrice.text = price
        }
        
        annotationView.addSubview(viewSmallPin)
        annotationView.canShowCallout = true
        annotationView.backgroundColor = UIColor.whiteColor()
        annotationView.layer.cornerRadius = 7
        
        //            let myPinImage = UIImageView(image: UIImage(named: "pin"))
        //            myPinImage.frame = CGRectMake(0, 0, 70, 70)
        //            annotationView.addSubview(myPinImage)
        //            let price = priceRandomizer(prices[currentSelection])
        //
        //            let label = UILabel(frame: CGRectMake(5, -5, 60, 60))
        //            label.text = "$\(price).99"
        //            if (price > 10 || price < 100) {
        //                var _: CGFloat = 8
        //            }
        //
        //            let button = UIButton(type: UIButtonType.RoundedRect)
        //            button.frame = CGRectMake(0, 0, 60, 23)
        //            button.setTitle("Reserve", forState: UIControlState.Normal)
        //            annotationView.rightCalloutAccessoryView = button
        //
        //            let leftButton = UIButton(type: UIButtonType.DetailDisclosure)
        //            leftButton.frame = CGRectMake(0, 0, 23, 23)
        //            annotationView.leftCalloutAccessoryView = leftButton
        //
        //            annotationView.canShowCallout = true
        //
        //            label.textColor = UIColor.whiteColor()
        //
        //            annotationView.addSubview(label)
        //            return annotationView
        
        var i = 0
        for _ in titles {
            var latitude: CLLocationDegrees!
            var longitude: CLLocationDegrees!
            latitude = CLLocationDegrees(latitudes[i])
            longitude = CLLocationDegrees(longitudes[i])
            var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            addStore(coordinate)
            i++
        }
        print("Added one pin!")
        return annotationView
    }
    
    func priceRandomizer(price:Int) -> Int {
        let range = Int(Double(price) * 0.20)
        let rangeUInt = UInt32(range)
        let priceUInt = UInt32(price)
        return Int(priceUInt +   arc4random_uniform(rangeUInt) - rangeUInt/2 )
    }
    
    //    func randomOffset() ->(Double,Double) {
    //        let number1 = (0.02 - 0) * Double(Double(arc4random()) / Double(UInt32.max))
    //        let number2 = (0.02 - 0) * Double(Double(arc4random()) / Double(UInt32.max))
    //        return (number1,number2)
    //    }
    
    @IBAction func addPopover(sender: UIBarButtonItem) {
        let profileOptions = UIAlertController()
        
        var currentUser = PFUser.currentUser()
        
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
                            print("This user is a farmer? \(self.isFarmer)")
                            self.switchToFarmer()
                        } else {
                            print("Something is not working with retrieving the farmer status.")
                            print(error)
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
    
    // Signup credentials
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
        
        let signupSheetController: UIAlertController = UIAlertController(title: "Sign in to Fresh", message: "Log into your Fresh account and connect with farmers around the world.", preferredStyle: .Alert)
        
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
        userEmail = userEmail.lowercaseString
        
        let user = PFUser()
        user.email = userEmail
        user.username = userEmail
        user.password = userPassword
        
        let userLogin = PFUser.currentUser()
        
        PFUser.logInWithUsernameInBackground(userEmail, password: userPassword) {
            (user: PFUser?, error: NSError?) -> Void in
            if userLogin != nil {
                print("Successfully logged in!")
                self.objectID = userLogin?.objectId
                print("Your objectID is \(self.objectID)")
            } else {
                print("Login failed!")
            }
        }
        
        if (PFUser.currentUser() == nil) {
            presentViewController(signupSheetController, animated: true, completion: nil)
        }
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        //            WalmartClient.search(searchController.searchBar.text!) { (names, images , prices) -> Void in
        //                self.names = names
        //                self.images = images
        //                self.prices = prices
        //                self.searchResultsTableViewController.tableView.reloadData()
    }
    
    func switchToFarmer() {
        var btnName: UIButton = UIButton()
        btnName.frame = CGRectMake(0, 0, 22, 22)
        btnName.setImage(UIImage(named: "plus"), forState: .Normal)
        btnName.addTarget(self, action: Selector("goToAddProduct"), forControlEvents: .TouchUpInside)
        
        //.... Set Right/Left Bar Button item
        var rightBarButton:UIBarButtonItem = UIBarButtonItem()
        rightBarButton.customView = btnName
        self.navigationItem.rightBarButtonItem = rightBarButton
    }
    
    func goToAddProduct() {
        let storyboard : UIStoryboard = UIStoryboard(name: "New", bundle: nil)
        let vc : ProductsTableViewController = storyboard.instantiateViewControllerWithIdentifier("products") as! ProductsTableViewController
        
        let navigationController = UINavigationController(rootViewController: vc)
        
        self.presentViewController(navigationController, animated: true, completion: nil)
    }
    
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