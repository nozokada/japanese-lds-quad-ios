//
//  PurchaseViewController.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 3/3/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit
import StoreKit

class PurchaseViewController: UIViewController {
    
    let productIdentifiers = [Constants.ProductID.allFeaturesPass]
    
    var allFeaturesPassName: String!
    var allFeaturesPassPrice: String!
    
    var isAuthorizedForPayments: Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    @IBOutlet weak var allFeaturesPassTitleLabel: UILabel!
    @IBOutlet weak var allFeaturesPassDescriptionLabel: UILabel!
    @IBOutlet weak var allFeaturePassPurchaseButton: MainButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        StoreManager.shared.delegate = self
        StoreManager.shared.startProductRequest(with: productIdentifiers)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }
    
    func reload() {
        allFeaturesPassTitleLabel.text = allFeaturesPassName
        let buttonTitle = "\("allFeaturesPassPurchaseButtonLabel".localized) \(allFeaturesPassPrice ?? "")"
        allFeaturePassPurchaseButton.setTitle(buttonTitle, for: .normal)
        allFeaturesPassDescriptionLabel.text = "allFeaturesDescriptionLabel".localized
    }
}

extension PurchaseViewController: StoreManagerDelegate {
    
    func storeManagerDidReceiveProducts(_ products: [SKProduct]) {
        let allFeaturesPass = products.first
        allFeaturesPassName = allFeaturesPass?.localizedTitle
        allFeaturesPassPrice = allFeaturesPass?.regularPrice
        DispatchQueue.main.async {
            self.reload()
        }
    }
}
