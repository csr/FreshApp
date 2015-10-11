//
//  ProductsTableViewController.swift
//  Fresh
//
//  Created by Cesare de Cal on 11/10/15.
//  Copyright © 2015 Chimica. All rights reserved.
//

import UIKit
import Parse
import Bolts

var inserimentoObjectID: String!
var allObjects: [String] = []

class ProductsTableViewController: UITableViewController {
    
    @IBOutlet weak var textFieldTitle: FloatLabelTextField!
    @IBOutlet weak var textFieldDescription: FloatLabelTextField!
    @IBOutlet weak var textFieldPrice: FloatLabelTextField!
    @IBOutlet weak var textFieldLocation: FloatLabelTextField!
    
    @IBOutlet weak var buttonDone: UIBarButtonItem!
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController!.navigationBar.barTintColor = UIColor(red: 131/255, green: 192/255, blue: 101/255, alpha: 1)
    }
    
    @IBAction func tapOnButtonDone(sender: AnyObject) {
        
        var inserimento = PFObject(className: "Products")
        inserimento["Title"] = textFieldTitle.text
        inserimento["Description"] = textFieldDescription.text
        inserimento["Price"] = textFieldPrice.text
        inserimento["Latitude"] = 45.439171
        inserimento["Longitude"] = 9.258177
        inserimento.saveInBackgroundWithBlock {
            (success: Bool, error: NSError?) -> Void in
            if (success) {
                inserimentoObjectID = inserimento.objectId
                allObjects.append(inserimentoObjectID)
                print("The object ID of inserimento is \(inserimentoObjectID).")
            } else {
                print("Error!")
            }
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
}

class ProductsNavigationViewController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.barTintColor = UIColor.whiteColor()
        navigationBar
    }
    
}