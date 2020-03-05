//
//  PurchaseChangeDelegate.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 3/4/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit

protocol PurchaseChangeDelegate {
    
    func presentPuchaseViewController()
}


extension UIViewController: PurchaseChangeDelegate {
    
    func presentPuchaseViewController() {
        if let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.purchase) as? PurchaseViewController {
            viewController.delegate = self
            viewController.modalPresentationStyle = .overCurrentContext
            viewController.modalTransitionStyle = .crossDissolve
            
            if let settingsViewController = self as? SettingsViewController {
                settingsViewController.dismiss(animated: true, completion: nil)
                if let delegate = settingsViewController.delegate as? PurchaseChangeDelegate {
                    delegate.presentPuchaseViewController()
                }
            } else {
                present(viewController, animated: true, completion: nil)
            }
        }
    }
}
