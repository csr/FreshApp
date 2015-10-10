//
//  TableViewController.swift
//  Fresh
//
//  Created by Owner on 10/10/15.
//  Copyright © 2015 Chimica. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {
    
    override func tableView(tableView: UITableView,
        numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    override func tableView(tableView: UITableView,
        cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "cell")
    }

}