//
//  PurchaseChangeDelegate.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 3/4/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit

protocol PurchaseChangeDelegate {

}


extension PurchaseChangeDelegate where Self: UIViewController {
    
    func presentPuchaseViewController() {
        if let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.purchase) as? PurchaseViewController {
            viewController.delegate = self
            viewController.modalPresentationStyle = .overCurrentContext
            viewController.modalTransitionStyle = .crossDissolve
            present(viewController, animated: true, completion: nil)
        }
    }
}
