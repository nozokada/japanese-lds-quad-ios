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
    
    let productIdentifiers = [Constants.AppInfo.allFeaturesPassProductID]
    
    var allFeaturesPass: SKProduct?
    var allFeaturesPassName: String!
    var allFeaturesPassPrice: String!
    var spinner: MainIndicatorView?
    
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
        fetchProductInformation()
    }
    
    fileprivate func prepareBackgroundView() {
        modalView.layer.cornerRadius = Constants.Size.viewCornerRadius
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(blurEffectView, at: 0)
    }
    
    fileprivate func reload() {
        titleLabel.text = allFeaturesPass?.localizedTitle ?? "allFeaturesPassTitleLabel".localized
        let buttonTitle = "\("allFeaturesPassPurchaseButtonLabel".localized) \(allFeaturesPass?.regularPrice ?? "")"
        purchaseButton.setTitle(buttonTitle, for: .normal)
        restoreButton.setTitle("allFeaturesPassRestoreButtonLabel".localized, for: .normal)
        descriptionLabel.text = "allFeaturesDescriptionLabel".localized
    }
    
    fileprivate func fetchProductInformation() {
        if StoreObserver.shared.isAuthorizedForPayments {
            StoreManager.shared.startProductRequest(with: productIdentifiers)
        } else {
            alert(with: "productRequestStatus".localized, message: "purchaseNotAllowed".localized, close: true)
        }
    }
    
    fileprivate func alert(with title: String, message: String, close: Bool = false) {
        let handler = close ? {(alert: UIAlertAction) in self.dismiss(animated: true, completion: nil) } : nil
        let alertController = Utilities.shared.alert(view: view, title: title, message: message, handler: handler)
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func purchaseButtonTapped(_ sender: Any) {
        if let pass = allFeaturesPass {
            purchaseButton.disable()
            StoreObserver.shared.buy(pass)
        }
    }
    
    @IBAction func restoreButtonTapped(_ sender: Any) {
        restoreButton.disable()
        StoreObserver.shared.restore()
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }
}

extension PurchaseViewController: StoreManagerDelegate {
    
    func storeManagerDidReceiveProducts(_ products: [SKProduct]) {
        allFeaturesPass = products.first
        reload()
    }
    
    func storeManagerDidReceiveMessage(_ message: String) {
        alert(with: "productRequestStatus".localized, message: message, close: true)
    }
}

extension PurchaseViewController: StoreObserverDelegate {
    
    func storeObserverPurchaseDidSucceed() {
        purchaseButton.enable()
        alert(with: "productRequestStatus".localized, message: "purchaseComplete".localized, close: true)
    }
    
    func storeObserverPurchaseDidCancel() {
        purchaseButton.enable()
    }
    
    func storeObserverRestoreDidSucceed() {
        restoreButton.enable()
        alert(with: "productRequestStatus".localized, message: "restoreComplete".localized, close: true)
    }
    
    func storeObserverRestoreDidCancel() {
        restoreButton.enable()
    }
    
    func storeObserverDidReceiveMessage(_ message: String) {
        purchaseButton.enable()
        restoreButton.enable()
        alert(with: "purchaseStatus".localized, message: message)
    }
}
