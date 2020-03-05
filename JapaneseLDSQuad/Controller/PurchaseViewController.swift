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
    
    var delegate: PurchaseViewDelegate?
    
    let productIdentifiers = [Constants.ProductID.allFeaturesPass]
    
    var allFeaturesPassName: String!
    var allFeaturesPassPrice: String!
    
    var isAuthorizedForPayments: Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    @IBOutlet weak var modalView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var purchaseButton: MainButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        StoreManager.shared.delegate = self
        StoreManager.shared.startProductRequest(with: productIdentifiers)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }
    
    func prepareViews() {
        modalView.layer.cornerRadius = 5
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(blurEffectView, at: 0)
    }
    
    func reload() {
        titleLabel.text = allFeaturesPassName
        let buttonTitle = "\("allFeaturesPassPurchaseButtonLabel".localized) \(allFeaturesPassPrice ?? "")"
        purchaseButton.setTitle(buttonTitle, for: .normal)
        descriptionLabel.text = "allFeaturesDescriptionLabel".localized
        prepareViews()
    }
    
    @IBAction func purchaseButtonTapped(_ sender: Any) {
    }
    
    
    @IBAction func restoreButtonTapped(_ sender: Any) {
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
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
