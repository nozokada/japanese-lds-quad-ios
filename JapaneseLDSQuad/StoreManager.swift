//
//  StoreManager.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 3/3/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import StoreKit

class StoreManager: NSObject {
    
    var delegate: StoreManagerDelegate?
    
    static let shared = StoreManager()
    
    var availableProducts = [SKProduct]()
    var productRequest: SKProductsRequest!
    
    private override init() {}
    
    func startProductRequest(with identifiers: [String]) {
        fetchProducts(matchingIdentifiers: identifiers)
    }
    
    fileprivate func fetchProducts(matchingIdentifiers identifiers: [String]) {
        let productIdentifiers = Set(identifiers)
        productRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productRequest.delegate = self
        productRequest.start()
    }
}

extension StoreManager: SKProductsRequestDelegate {
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if !response.products.isEmpty {
            availableProducts = response.products
            DispatchQueue.main.async {
                self.delegate?.storeManagerDidReceiveProducts(self.availableProducts)
            }
        }
    }
}

extension StoreManager: SKRequestDelegate {
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.delegate?.storeManagerDidReceiveMessage(error.localizedDescription)
        }
    }
}

