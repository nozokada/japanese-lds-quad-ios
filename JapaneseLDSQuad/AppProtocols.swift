//
//  AppProtocols.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 3/5/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import StoreKit

protocol MainWebViewDelegate {
    
    func showAlert(with title: String, message: String)
    
    func showPurchaseViewController()
}

protocol ContentChangeDelegate {
    
    func updateContentView()
}

protocol StoreManagerDelegate {
    
    func storeManagerDidReceiveProducts(_ products: [SKProduct])

    func storeManagerDidReceiveMessage(_ message: String)
}

protocol StoreObserverDelegate {
    
    func storeObserverPurchaseDidSucceed()
    
    func storeObserverPurchaseDidCancel()

    func storeObserverRestoreDidSucceed()
    
    func storeObserverRestoreDidCancel()

    func storeObserverDidReceiveMessage(_ message: String)
}

protocol AuthenticationManagerDelegate {
    
    func authenticationManagerDidSucceed()
    
    func authenticationManagerDidReceiveMessage(_ message: String)
}

protocol FirestoreManagerDelegate {
    
    func firestoreManagerDidSucceed()
}

protocol DialogueViewDelegate {
    
    func dialogueViewDidReceiveOK()
}

protocol PurchaseViewDelegate {
    
    func presentPuchaseViewController()
}

extension UIViewController: PurchaseViewDelegate {
    
    func presentPuchaseViewController() {
        guard let viewController = storyboard?.instantiateViewController(
            withIdentifier: Constants.StoryBoardID.purchase) as? PurchaseViewController else {
            return
        }
        viewController.modalPresentationStyle = .overFullScreen
        viewController.modalTransitionStyle = .crossDissolve
        present(viewController, animated: true, completion: nil)
    }
}
