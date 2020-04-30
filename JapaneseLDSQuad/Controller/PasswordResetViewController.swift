//
//  PasswordResetViewController.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 4/29/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit

class PasswordResetViewController: UIViewController {
    
    @IBOutlet weak var messageTextLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var sendButton: MainButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "passwordResetViewTitle".localized
        messageTextLabel.text = "passwordResetDescriptionLabel".localized
        emailTextField.placeholder = "emailPlaceholder".localized
        sendButton.setTitle("passwordResetEmailSendButtonLabel".localized, for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AuthenticationManager.shared.delegate = self
        messageTextLabel.textColor = Utilities.shared.getTextColor()
        view.backgroundColor = Utilities.shared.getBackgroundColor()
    }
    
    fileprivate func alert(title: String, message: String, close: Bool = false) {
        let alertController = Utilities.shared.alert(view: view, title: title, message: message, handler: nil)
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func sendButtonTapped(_ sender: Any) {
        guard let email = emailTextField.text, !email.isEmpty else {
            alert(title: "passwordResetError".localized, message: "fillAllFields".localized)
            return
        }
        sendButton.disable()
        AuthenticationManager.shared.sendPasswordReset(to: email)
    }
}

extension PasswordResetViewController: AuthenticationManagerDelegate {
    
    func authenticationManagerDidSucceed() {
        messageTextLabel.text = "passwordResetEmailSentDescriptionLabel".localized
        sendButton.setTitle("passwordResetEmailSentButtonLabel".localized, for: .normal)
    }
    
    func authenticationManagerDidReceiveMessage(_ message: String) {
        sendButton.enable()
        alert(title: "passwordResetError".localized, message: message)
    }
}
