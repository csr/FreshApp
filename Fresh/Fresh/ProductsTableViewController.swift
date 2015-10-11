//
//  ProductsTableViewController.swift
//  Fresh
//
//  Created by Cesare de Cal on 11/10/15.
//  Copyright © 2015 Chimica. All rights reserved.
//

import UIKit

class ProductsTableViewController: UITableViewController {
    
    @IBOutlet weak var buttonDone: UIBarButtonItem!
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController!.navigationBar.barTintColor = UIColor(red: 131/255, green: 192/255, blue: 101/255, alpha: 1)
    }
    
    @IBAction func tapOnButtonDone(sender: AnyObject) {
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