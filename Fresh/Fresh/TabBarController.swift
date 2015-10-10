////
//  TabBarController.swift
//  Fresh
//
//  Created by Owner on 10/10/15.
//  Copyright © 2015 Chimica. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController {
    let color = UIColor(red: 1, green: 1, blue: 39, alpha: 1.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UITabBar.appearance().barTintColor = UIColor(red: 131/255, green: 192/255, blue: 101/255, alpha: 1)
    }
}