//
//  RegisterViewController.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 3/22/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit
import FirebaseAuth

class RegisterViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var registerButton: MainButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "registerViewTitle".localized
        usernameTextField.placeholder = "usernamePlaceholder".localized
        emailTextField.placeholder = "emailPlaceholder".localized
        passwordTextField.placeholder = "passwordPlaceholder".localized
        registerButton.setTitle("registerButtonLabel".localized, for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AuthenticationManager.shared.delegate = self
        view.backgroundColor = Utilities.shared.getBackgroundColor()
    }
    
    fileprivate func alert(title: String, message: String, close: Bool = false) {
        let alertController = Utilities.shared.alert(view: view, title: title, message: message, handler: nil)
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func registerButtonTapped(_ sender: Any) {
        guard let email = emailTextField.text, !email.isEmpty,
            let password = passwordTextField.text, !password.isEmpty,
            let username = usernameTextField.text, !username.isEmpty else {
                alert(title: "registrationError".localized, message: "fillAllFields".localized)
                return
        }
        registerButton.disable()
        registerButton.showSpinner()
        AuthenticationManager.shared.createUser(email: email, password: password, username: username)
    }
}

extension RegisterViewController: AuthenticationManagerDelegate {
    
    func authenticationManagerDidSucceed() {
        registerButton.hideSpinner()
        registerButton.enable()
        if let viewController = navigationController?.viewControllers.first as? AuthenticationManagerDelegate {
            viewController.authenticationManagerDidSucceed()
        }
    }
    
    func authenticationManagerDidReceiveMessage(_ message: String) {
        registerButton.hideSpinner()
        registerButton.enable()
        alert(title: "registrationError".localized, message: message)
    }
}
