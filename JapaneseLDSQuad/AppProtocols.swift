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

protocol StoreManagerDelegate {
    
    func storeManagerDidReceiveProducts(_ products: [SKProduct])

    func storeManagerDidReceiveMessage(_ message: String)
}

protocol StoreObserverDelegate {
    
    func storeObserverPurchaseDidSucceed()

    func storeObserverRestoreDidSucceed()

    func storeObserverDidReceiveMessage(_ message: String)
}

protocol AuthenticationManagerDelegate {
    
    func authenticationManagerDidSucceed()
    
    func authenticationManagerDidReceiveMessage(_ message: String)
}

protocol FirestoreManagerDelegate {
    
    func firestoreManagerDidSyncBookmarks()
}
