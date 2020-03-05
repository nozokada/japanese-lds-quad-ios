//
//  MainTabBarController.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/3/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController, UITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        tabBar.items?[0].title = "readTabBarItemTitle".localized
        tabBar.items?[1].title = "searchTabBarItemTitle".localized
        tabBar.items?[2].title = "bookmarksTabBarItemTitle".localized
        tabBar.items?[3].title = "highlightsTabBarItemTitle".localized
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if let identifier = viewController.restorationIdentifier,
            AppUtility.shared.isPaid(restorationIdentifider: identifier) {
            if !PurchaseManager.shared.allFeaturesUnlocked {
                presentPuchaseViewController()
                return false
            }
        }
        return true
    }
}
