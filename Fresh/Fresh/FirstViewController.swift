import UIKit
import MapKit
import Parse
import Bolts

class FirstViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UISearchBarDelegate, UIPopoverPresentationControllerDelegate {
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
        
        
    }
    
    // Objects
    let locationManager: CLLocationManager = CLLocationManager() // the object that provides us the location qdata
    var userLocation: CLLocation!
    
  
    
    // Flag variables
    var isFarmer = false
    var isLoggedIn = false
    
    // UI elements
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var getLocationButton: UIButton!
    @IBOutlet weak var profileNavBarButton: UIBarButtonItem!
    @IBOutlet weak var viewGetLocation: UIView!
    
    
    
    var searchController:UISearchController!
    var searchResultsTableViewController:UITableViewController!
    var storePins:[CustomPin] = []
    var images:[String] = []
    var names:[String] = []
    var prices:[Int] = []
    var currentSelection:Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        mapView.showsUserLocation = true

        searchResultsTableViewController = UITableViewController()
        searchResultsTableViewController.view.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(1.0)
        searchController = UISearchController(searchResultsController: searchResultsTableViewController)
        //searchController.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.delegate = self
        self.navigationItem.titleView = searchController.searchBar
        searchController.searchBar.placeholder = "Search for fresh products..."
        
        
        // Change Navigation Color
        navigationController!.navigationBar.barTintColor = UIColor(red: 131/255, green: 192/255, blue: 101/255, alpha: 1)

        self.getUserLocation(self)
        print("Requesting your current location...")
        getUserLocation(self)
        
        ///Status Bar
        
        
        
        // Setting up Get Location UIView
        viewGetLocation.alpha = 0.9
        viewGetLocation.layer.cornerRadius = 5
    }
    
    
    @IBAction func didClickProfile(sender: AnyObject) {

    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func tapOnGetLocation(sender: AnyObject) {
        
        UIView.animateWithDuration(0.4, animations: {
            self.getLocationButton.setImage(UIImage(named: "request1"), forState: UIControlState.Normal)
        })
        getUserLocation(self)
    }
    
    func getUserLocation(sender: AnyObject)
    {
        locationManager.delegate = self // instantiate the CLLocationManager object
        
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            locationManager.requestAlwaysAuthorization()
        }
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        self.locationManager.startUpdatingLocation()
        // continuously send the application a stream of location data
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        let newLocation = locations.last!
        mapView.setCenterCoordinate(newLocation.coordinate, animated: true)
        let viewRegion = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 1300, 1300)
        mapView.setRegion(viewRegion, animated: true)
        
        manager.stopUpdatingLocation()
        
    }
    
    // Display the custom view
    var stores = ["Walmart","Target","Costco","Meijer"]
    
    // Display the custom view
    func addStore(coordinate: CLLocationCoordinate2D, price: Int)
    {
        print("addStore called!")
        let randomPair = randomOffset()
        print(coordinate)
        let newCoordinate = CLLocationCoordinate2D(latitude: coordinate.latitude + Double(randomPair.0), longitude: coordinate.longitude   +  Double(randomPair.1))
        print(newCoordinate)
        let storeTitle = stores[ Int(arc4random_uniform(UInt32(stores.count - 1)))  ]
        let storePin = CustomPin(title: storeTitle , locationName: "", discipline: "", coordinate: newCoordinate)
        storePins.append(storePin)
        mapView.addAnnotation(storePin)
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return mapView.dequeueReusableAnnotationViewWithIdentifier("")
        } else {
            let annotationView = MKAnnotationView(frame: CGRectMake(0, 0, 70, 70))
            //view.backgroundColor = UIColor.whiteColor()
            let myPinImage = UIImageView(image: UIImage(named: "pin"))
            myPinImage.frame = CGRectMake(0, 0, 70, 70)
            annotationView.addSubview(myPinImage)
            let price = priceRandomizer(prices[currentSelection])
            
            let label = UILabel(frame: CGRectMake(5, -5, 60, 60))
            label.text = "$\(price).99"
            var font: CGFloat!
            if (price > 10 || price < 100) {
                font = 8
            } else {
                font = 6
            }
            
            let button = UIButton(type: UIButtonType.RoundedRect)
            button.frame = CGRectMake(0, 0, 60, 23)
            button.setTitle("Reserve", forState: UIControlState.Normal)
            annotationView.rightCalloutAccessoryView = button
            
            let leftButton = UIButton(type: UIButtonType.DetailDisclosure)
            leftButton.frame = CGRectMake(0, 0, 23, 23)
            annotationView.leftCalloutAccessoryView = leftButton
            
            annotationView.canShowCallout = true
            
            label.textColor = UIColor.whiteColor()
            
            annotationView.addSubview(label)
            return annotationView
        }
    }
    
    func priceRandomizer(price:Int) -> Int {
        let range = Int(Double(price) * 0.20)
        let rangeUInt = UInt32(range)
        let priceUInt = UInt32(price)
        return Int(priceUInt +   arc4random_uniform(rangeUInt) - rangeUInt/2 )
    }
    
    func randomOffset() ->(Double,Double) {
        let number1 = (0.02 - 0) * Double(Double(arc4random()) / Double(UInt32.max))
        let number2 = (0.02 - 0) * Double(Double(arc4random()) / Double(UInt32.max))
        return (number1,number2)
    }
    
    // UIPresentationController
    @IBAction func addPopover(sender: UIBarButtonItem) {
        let profileOptions = UIAlertController()
        var accountButton: String = ""
        
        if (isLoggedIn) {
            accountButton = "Sign out"
        } else {
            accountButton = "Log in"
        }
        
        //profileOptions.title = "Fresh ID"
        profileOptions.addAction(UIAlertAction(title: accountButton, style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction!) -> Void in
        
            if (!self.isLoggedIn) {
                self.signUp()
            }
        }))
        profileOptions.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Destructive, handler: nil))
        
        // Display the action sheet
        profileOptions.popoverPresentationController?.barButtonItem = profileNavBarButton
        presentViewController(profileOptions, animated: true, completion: nil)
    }

    func login() {
        let loginSheetController: UIAlertController = UIAlertController(title: "Login to Fresh", message: "Login to your Fresh account.", preferredStyle: .Alert)
        let loginAction: UIAlertAction = UIAlertAction(title: "Login", style: .Default) { action -> Void in } // create and add a login button
        loginSheetController.addAction(loginAction)
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in } // create and add a cancel button
        loginSheetController.addAction(cancelAction)
        loginSheetController.addTextFieldWithConfigurationHandler ({(textField: UITextField!) in
            textField.textColor = UIColor.blackColor()
            textField.placeholder = "Username"
            textField.secureTextEntry = false
            //inputTextField = textField
        })
        
        loginSheetController.addTextFieldWithConfigurationHandler ({(textField: UITextField!) in
            textField.textColor = UIColor.blackColor()
            textField.placeholder = "Password"
            textField.secureTextEntry = true
            //inputTextField = textField
        })

        presentViewController(loginSheetController, animated: true, completion: nil)
    }
    
    // Signup credentials
    var userEmail = ""
    var userPassword = ""
    
    func signUp() {
        var emailTextField: UITextField?
        var passwordTextField: UITextField?
        
        let signupSheetController: UIAlertController = UIAlertController(title: "Sign up to Fresh", message: "Creating an account allows you to connect with farmers and buy great products.", preferredStyle: .Alert)
    
        let signupAction: UIAlertAction = UIAlertAction(title: "Sign up", style: .Default) { action -> Void in
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
        
    
        // Start activity indicator
        
        // Create the user
        var user = PFUser()
        user.username = userEmail
        user.email = userEmail
        user.password = userPassword
        
        presentViewController(signupSheetController, animated: true, completion: nil)
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        //            WalmartClient.search(searchController.searchBar.text!) { (names, images , prices) -> Void in
        //                self.names = names
        //                self.images = images
        //                self.prices = prices
        //                self.searchResultsTableViewController.tableView.reloadData()
    }
}
    
//    extension FirstViewController: UISearchControllerDelegate
//    {
//        func willPresentSearchController(searchController: UISearchController) {
//            //caculate frame here
//            let statusBarHeight = UIApplication.sharedApplication().statusBarFrame.height
//            let navigationBarFrame = navigationController!.navigationBar.frame
//            let tableViewY = navigationBarFrame.height + statusBarHeight
//            let tableViewHeight = mapView.frame.height - navigationBarFrame.height  - toolBar.frame.height
//            
//            searchResultsTableViewController.tableView.frame = CGRectMake(0, tableViewY, navigationBarFrame.width, tableViewHeight)
//            
//            
//        }
//        override func viewWillLayoutSubviews() {
//        }
//        func presentSearchController(searchController: UISearchController) {
//        }
//        func didPresentSearchController(searchController: UISearchController) {
//        }
//    }
    
    class CustomPin: NSObject, MKAnnotation {
        let title: String?
        let locationName: String?
        let discipline: String?
        let coordinate: CLLocationCoordinate2D
        
        init(title: String, locationName: String, discipline: String, coordinate: CLLocationCoordinate2D) {
            self.title = title
            self.locationName = locationName
            self.discipline = discipline
            self.coordinate = coordinate
            
            super.init()
        }
        
        var subtitle: String? {
            return locationName
        }
    }
//    extension FirstViewController: UITableViewDelegate,UITableViewDataSource
//    {
//        func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//            return names.count
//        }
//        func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//            let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
//            if names.count == 0
//            {
//                return cell
//            }
//            cell.textLabel!.text =  "\(names[indexPath.item])  $\(prices[indexPath.item])"
//            return cells
//        }
//        func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//            currentSelection = indexPath.item
//            for i in 0...10
//            {
//                addStore(mapView.userLocation.coordinate, price: prices[currentSelection])
//            }
//            searchController.active = false
//        }
//}