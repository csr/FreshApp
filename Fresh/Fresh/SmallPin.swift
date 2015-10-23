//
//  smallPin.swift
//  Fresh
//
//  Created by Cesare de Cal on 17/10/15.
//  Copyright © 2015 Chimica. All rights reserved.
//

import UIKit

class SmallPin: UIView {
    
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelPrice: UILabel?
    @IBOutlet weak var smallPingBg: UIImageView!
    
    override func awakeFromNib() {
        smallPingBg.image = UIImage(named: "smallPin")
        smallPingBg.layer.borderWidth = 1
        //labelTitle.text = "Default"
        //abelPrice!.text = "Default"
    }
    
    class func loadNib() -> SmallPin {
        return (UINib(nibName: "SmallPin", bundle: NSBundle.mainBundle()).instantiateWithOwner(self, options: nil).first) as! SmallPin
    }
}