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
    
    var allFeaturesUnlocked = true
    
    private override init() {
        super.init()
        allFeaturesUnlocked = UserDefaults.standard.bool(forKey: Constants.Config.pass)
    }
    
    func unlockProduct(withIdentifier productIdentifier: String) {
        switch productIdentifier {
        case Constants.ProductID.allFeaturesPass:
            enableAllFeatures(purchased: true)
        default:
            break
        }
    }
    
    func enableAllFeatures(purchased: Bool) {
        UserDefaults.standard.set(purchased, forKey: Constants.Config.pass)
        allFeaturesUnlocked = purchased
    }
    
    func handlePurchased(_ transaction: SKPaymentTransaction) {
        debugPrint("Purchase succeeded")
        let productIdentifier = transaction.payment.productIdentifier
        unlockProduct(withIdentifier: productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    func handleFailed(_ transaction: SKPaymentTransaction) {
        debugPrint("Purchase failed")
        var message = "Purchase of \(transaction.payment.productIdentifier) failed"
        if let error = transaction.error {
            message += "\n\(error.localizedDescription)"
        }
        
        if (transaction.error as? SKError)?.code != .paymentCancelled {
            debugPrint(message)
        }
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    func handleRestored(_ transaction: SKPaymentTransaction) {
        if let productIdentifier = transaction.original?.payment.productIdentifier {
            unlockProduct(withIdentifier: productIdentifier)
        }
        SKPaymentQueue.default().finishTransaction(transaction)
    }
}

extension PurchaseManager: SKPaymentTransactionObserver {
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing: break
            case .deferred: break
            case .purchased: handlePurchased(transaction)
            case .failed: handleFailed(transaction)
            case .restored: handleRestored(transaction)
            @unknown default: fatalError()
            }
        }
    }
}
