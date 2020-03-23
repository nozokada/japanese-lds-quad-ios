//
//  LoginViewController.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 3/21/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: MainButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "loginViewTitle".localized
    }
    
    fileprivate func alert(message: String, close: Bool = false) {
        let title = "loginError".localized
        let alertController = Utilities.shared.alert(view: view, title: title, message: message, handler: nil)
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        guard let email = emailTextField.text, !email.isEmpty,
            let password = passwordTextField.text, !password.isEmpty else {
                self.alert(message: "fillAllFields".localized)
                return
        }
        loginButton.disable()
        AuthenticationManager.shared.signIn(email: email, password: password) { success, error in
            if success {
                self.navigationController?.popToRootViewController(animated: true)
            } else {
                if let error = error {
                    self.alert(message: error.localizedDescription)
                }
            }
            self.loginButton.enable()
        }
    }
    
    @IBAction func signupButtonTapped(_ sender: Any) {
        if let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.signup) {
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}
