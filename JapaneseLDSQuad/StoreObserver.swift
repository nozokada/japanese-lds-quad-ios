//
//  StoreObserver.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/4/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import Foundation
import StoreKit

class StoreObserver: NSObject {

    static var shared = StoreObserver()
    
    var isAuthorizedForPayments: Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    var allFeaturesUnlocked = true
    
    private override init() {
        super.init()
        allFeaturesUnlocked = UserDefaults.standard.bool(forKey: Constants.Config.pass)
    }
    
    func enableAllFeatures(purchased: Bool) {
        UserDefaults.standard.set(purchased, forKey: Constants.Config.pass)
        allFeaturesUnlocked = purchased
    }
    
    func unlockProduct(withIdentifier productIdentifier: String) {
        switch productIdentifier {
        case Constants.ProductID.allFeaturesPass:
            enableAllFeatures(purchased: true)
        default:
            break
        }
    }
    
    func buy(_ product: SKProduct) {
        let payment = SKMutablePayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    func restore() {
        SKPaymentQueue.default().restoreCompletedTransactions()
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

extension StoreObserver: SKPaymentTransactionObserver {
    
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
