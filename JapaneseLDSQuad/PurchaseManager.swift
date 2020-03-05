//
//  PurchaseManager.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 3/5/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import Foundation

class PurchaseManager: NSObject {
    
    static let shared = PurchaseManager()
    
    var allFeaturesUnlocked = false
    
    private override init() {
        super.init()
        allFeaturesUnlocked = UserDefaults.standard.bool(forKey: Constants.Config.pass)
    }
    
    func enableAllFeatures() {
        UserDefaults.standard.set(true, forKey: Constants.Config.pass)
        allFeaturesUnlocked = true
    }
    
    func unlockProduct(withIdentifier productIdentifier: String) {
        switch productIdentifier {
        case Constants.ProductID.allFeaturesPass:
            enableAllFeatures()
        default:
            break
        }
    }
}
