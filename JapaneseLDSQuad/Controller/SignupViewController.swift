//
//  SignupViewController.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 3/22/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit

class SignupViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var createAccountButton: MainButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "signupViewTitle".localized
    }
    
    fileprivate func alert(message: String, close: Bool = false) {
        let title = "singupError".localized
        let alertController = Utilities.shared.alert(view: view, title: title, message: message, handler: nil)
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func createAccountButtonTapped(_ sender: Any) {
        guard let email = emailTextField.text, !email.isEmpty,
            let password = passwordTextField.text, !password.isEmpty,
            let username = usernameTextField.text, !username.isEmpty else {
                self.alert(message: "fillAllFields".localized)
                return
        }
        createAccountButton.disable()
        AuthenticationManager.shared.createUser(email: email, password: password, username: username) { success, error in
            if success {
                self.navigationController?.popToRootViewController(animated: true)
            } else {
                if let error = error {
                    self.alert(message: error.localizedDescription)
                }
            }
            self.createAccountButton.enable()
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        navigationController?.popToRootViewController(animated: true)
    }
}
