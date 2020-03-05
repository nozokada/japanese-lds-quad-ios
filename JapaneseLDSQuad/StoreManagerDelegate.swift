//
//  StoreManagerDelegate.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 3/3/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import StoreKit

protocol StoreManagerDelegate {
    
    func storeManagerDidReceiveProducts(_ products: [SKProduct])
}
