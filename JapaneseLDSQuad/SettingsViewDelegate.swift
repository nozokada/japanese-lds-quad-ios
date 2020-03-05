//
//  SettingsViewDelegate.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/15/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit

@objc protocol SettingsViewDelegate {
    
    func reload()
}

extension SettingsViewDelegate where Self: UIViewController {
    
    func setSettingsBarButton() {
        let settingsButton = UIBarButtonItem(image: UIImage(named: "Ellipsis"), style: .plain, target: self, action: #selector(presentSettingsViewController(sender:)))
        if let barButtonItems = navigationItem.rightBarButtonItems {
            navigationItem.rightBarButtonItems = barButtonItems + [settingsButton]
        } else {
            navigationItem.rightBarButtonItem = settingsButton
        }
    }
}

extension UIViewController {
    
    @objc func presentSettingsViewController(sender: UIBarButtonItem) {
        if let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.settings) as? SettingsViewController {
            viewController.delegate = self as? SettingsViewDelegate
            viewController.modalPresentationStyle = .popover
            viewController.preferredContentSize = Constants.Size.settingsViewDimension
            
            guard let controller = viewController.popoverPresentationController else { return }
            controller.barButtonItem = sender
            controller.delegate = self
            present(viewController, animated: true, completion: nil)
        }
    }
}

extension UIViewController: UIPopoverPresentationControllerDelegate {

    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
