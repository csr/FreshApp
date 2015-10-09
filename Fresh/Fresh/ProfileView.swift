//
//  ProfileView.swift
//  Findy
//
//  Created by Oskar Zhang on 9/19/15.
//  Copyright © 2015 FindyTeam. All rights reserved.
//

import UIKit

class ProfileView: UIView {
    @IBOutlet weak var settings: UIButton!
    @IBOutlet weak var history: UIButton!
    @IBOutlet weak var friends: UIButton!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var switchFacebook: UISwitch!
    
    class func loadNib() -> ProfileView {
        return (UINib(nibName: "ProfileView", bundle: NSBundle.mainBundle()).instantiateWithOwner(self, options: nil).first) as! ProfileView
    }
    
    @IBAction func switchFacebook(sender: AnyObject) {
        showAlertFacebook()
    }
    
    override func awakeFromNib() {
        switchFacebook.setOn(false, animated: false)
        profileImage.layer.cornerRadius = profileImage.frame.height/2
        profileImage.clipsToBounds = true
        profileImage.layer.borderWidth = 1.0
        self.layer.shadowOpacity = 0.7
    }
    
    func showAlertFacebook() {
        let loginSheetController: UIAlertController = UIAlertController(title: "Connect to Facebook", message: "Get notified when your friends buy something interesting in your area!", preferredStyle: .Alert)
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
        var topVC = UIApplication.sharedApplication().keyWindow?.rootViewController
        while((topVC!.presentedViewController) != nil){
            topVC = topVC!.presentedViewController
        }
        topVC?.presentViewController(loginSheetController, animated: true, completion: nil)
    }
}