//
//  AppProtocols.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 3/5/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import StoreKit

protocol StoreManagerDelegate {
    
    func storeManagerDidReceiveProducts(_ products: [SKProduct])

    func storeManagerDidReceiveMessage(_ message: String)
}

protocol StoreObserverDelegate {
    
    func storeObserverPurchaseDidSucceed()

    func storeObserverRestoreDidSucceed()

    func storeObserverDidReceiveMessage(_ message: String)
}
