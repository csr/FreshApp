////
//  TabBarController.swift
//  Fresh
//
//  Created by Owner on 10/10/15.
//  Copyright © 2015 Chimica. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Change the color of the tab bar
        UITabBar.appearance().barTintColor = UIColor(red: 131/255, green: 192/255, blue: 101/255, alpha: 1)
        
        // Since we only have one tab, let's keep the tab bar hidden for now
        UITabBar.appearance().hidden = true
    }
}