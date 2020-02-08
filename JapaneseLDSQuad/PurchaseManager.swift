//
//  PurchaseManager.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/4/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import Foundation
import StoreKit

class PurchaseManager: NSObject {
    
    static var shared = PurchaseManager()
    
    let allFeaturesPassProductId = "com.nozokada.JapaneseLDSQuad.allFeaturesPass"
    var isPurchased = false
}
