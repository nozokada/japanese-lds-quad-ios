//
//  SettingsChangeDelegate.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/15/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit

@objc protocol SettingsChangeDelegate {
    
    func reload()
}

extension SettingsChangeDelegate where Self: UIViewController {
    
    func setSettingsBarButton() {
        let settingsButton = UIBarButtonItem(image: #imageLiteral(resourceName: "Settings"), style: .plain, target: self, action: #selector(presentSettingsViewController(sender:)))
        if let barButtonItems = navigationItem.rightBarButtonItems {
            navigationItem.rightBarButtonItems = barButtonItems + [settingsButton]
        } else {
            navigationItem.rightBarButtonItem = settingsButton
        }
    }
}

extension UIViewController: UIPopoverPresentationControllerDelegate {
    
    @objc func presentSettingsViewController(sender: UIBarButtonItem) {
        if let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.settings) as? SettingsViewController {
            viewController.delegate = self as? SettingsChangeDelegate
            viewController.modalPresentationStyle = .popover
            
            guard let controller = viewController.popoverPresentationController else { return }
            controller.barButtonItem = sender
            controller.delegate = self
            present(viewController, animated: true, completion: nil)
        }
    }
    
    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
