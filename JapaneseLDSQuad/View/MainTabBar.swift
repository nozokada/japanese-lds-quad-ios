//
//  MainTabBar.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/3/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit

@IBDesignable
class MainTabBar: UITabBar {

    override func awakeFromNib() {
        customizeViews()
    }
    
    override func prepareForInterfaceBuilder() {
        customizeViews()
    }
    
    func customizeViews() {
        barTintColor = Constants.NavigationBarColor.day
        tintColor = UIColor.white
        isTranslucent = false
    }
}
