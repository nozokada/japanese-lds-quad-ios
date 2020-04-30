//
//  SignupViewController.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 3/22/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit
import FirebaseAuth

class SignupViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var createAccountButton: MainButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "signupViewTitle".localized
        usernameTextField.placeholder = "usernamePlaceholder".localized
        emailTextField.placeholder = "emailPlaceholder".localized
        passwordTextField.placeholder = "passwordPlaceholder".localized
        createAccountButton.setTitle("createAccountButtonLabel".localized, for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AuthenticationManager.shared.delegate = self
    }
    
    fileprivate func alert(message: String, close: Bool = false) {
        let title = "signupError".localized
        let alertController = Utilities.shared.alert(view: view, title: title, message: message, handler: nil)
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func createAccountButtonTapped(_ sender: Any) {
        guard let email = emailTextField.text, !email.isEmpty,
            let password = passwordTextField.text, !password.isEmpty,
            let username = usernameTextField.text, !username.isEmpty else {
                alert(message: "fillAllFields".localized)
                return
        }
        createAccountButton.disable()
        AuthenticationManager.shared.createUser(email: email, password: password, username: username)
    }
}

extension SignupViewController: AuthenticationManagerDelegate {
    
    func authenticationManagerDidSucceed() {
        createAccountButton.enable()
        if let viewController = navigationController?.viewControllers.first as? AuthenticationManagerDelegate {
            viewController.authenticationManagerDidSucceed()
        }
    }
    
    func authenticationManagerDidReceiveMessage(_ message: String) {
        createAccountButton.enable()
        alert(message: message)
    }
}
