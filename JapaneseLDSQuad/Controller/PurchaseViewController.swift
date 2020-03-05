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
    
    var allFeaturesPass: SKProduct?
    var allFeaturesPassName: String!
    var allFeaturesPassPrice: String!
    
    var isAuthorizedForPayments: Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    @IBOutlet weak var modalView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var purchaseButton: MainButton!
    @IBOutlet weak var restoreButton: MainButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareBackgroundView()
        StoreObserver.shared.delegate = self
        StoreManager.shared.delegate = self
        StoreManager.shared.startProductRequest(with: productIdentifiers)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }
    
    func prepareBackgroundView() {
        modalView.layer.cornerRadius = 5
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(blurEffectView, at: 0)
    }
    
    func reload() {
        titleLabel.text = allFeaturesPass?.localizedTitle
        let buttonTitle = "\("allFeaturesPassPurchaseButtonLabel".localized) \(allFeaturesPass?.regularPrice ?? "")"
        purchaseButton.setTitle(buttonTitle, for: .normal)
        restoreButton.setTitle("allFeaturesPassRestoreButtonLabel".localized, for: .normal)
        descriptionLabel.text = "allFeaturesDescriptionLabel".localized
    }
    
    func alert(with title: String, message: String) {
        let alertController = Utilities.shared.alert(title, message: message)
        present(alertController, animated: true, completion: nil)
    }
    
    func handleRestoredSucceededTransaction() {
        debugPrint("Let the user know that restore succeeded")
    }
    
    @IBAction func purchaseButtonTapped(_ sender: Any) {
        if let pass = allFeaturesPass {
            StoreObserver.shared.buy(pass)
        }
    }
    
    
    @IBAction func restoreButtonTapped(_ sender: Any) {
        StoreObserver.shared.restore()
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension PurchaseViewController: StoreManagerDelegate {
    
    func storeManagerDidReceiveProducts(_ products: [SKProduct]) {
        allFeaturesPass = products.first
        DispatchQueue.main.async {
            self.reload()
        }
    }
    
    func storeManagerDidReceiveMessage(_ message: String) {
        alert(with: "Product Request Status", message: message)
    }
}

extension PurchaseViewController: StoreObserverDelegate {
    func storeObserverRestoreDidSucceed() {
        handleRestoredSucceededTransaction()
    }
    
    func storeObserverDidReceiveMessage(_ message: String) {
        alert(with: "Purchase Status", message: message)
    }
}
