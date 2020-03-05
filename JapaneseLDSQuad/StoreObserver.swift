//
//  StoreObserver.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/4/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import StoreKit

class StoreObserver: NSObject {
    
    var delegate: StoreObserverDelegate?

    static let shared = StoreObserver()
    
    var isAuthorizedForPayments: Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    var hasRestorablePurchases = false
    
    func buy(_ product: SKProduct) {
        let payment = SKMutablePayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    func restore() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func handlePurchased(_ transaction: SKPaymentTransaction) {
        debugPrint("Handling succeeded purchase")
        let productIdentifier = transaction.payment.productIdentifier
        PurchaseManager.shared.unlockProduct(withIdentifier: productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    func handleFailed(_ transaction: SKPaymentTransaction) {
        debugPrint("Handling failed purchase")
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
        hasRestorablePurchases = true
        PurchaseManager.shared.unlockProduct(withIdentifier: transaction.payment.productIdentifier)
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
    
    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            debugPrint("\(transaction.payment.productIdentifier) was removed from the queue")
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        if let error = error as? SKError, error.code != .paymentCancelled {
            DispatchQueue.main.async {
                self.delegate?.storeObserverDidReceiveMessage(error.localizedDescription)
            }
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        if !hasRestorablePurchases {
            DispatchQueue.main.async {
                self.delegate?.storeObserverDidReceiveMessage("There are no restorable purchases")
            }
        }
    }
}
