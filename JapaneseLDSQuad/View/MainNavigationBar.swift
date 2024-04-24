//MainNavigationController
//  MainNavigationBar.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/3/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit

@IBDesignable
class MainNavigationBar: UINavigationBar {

    override func awakeFromNib() {
        customizeViews()
    }
    
    override func prepareForInterfaceBuilder() {
        customizeViews()
    }
    
    func customizeViews() {
        barTintColor = Constants.NavigationBarColor.day
        titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        tintColor = UIColor.white
        isTranslucent = false
        
        if #available(iOS 13.0, *) {
            let navigationBarAppearance = UINavigationBarAppearance()
            navigationBarAppearance.titleTextAttributes = titleTextAttributes!
            navigationBarAppearance.backgroundColor = barTintColor
            standardAppearance = navigationBarAppearance
            scrollEdgeAppearance = navigationBarAppearance
            compactAppearance = navigationBarAppearance
        }
    }
}
