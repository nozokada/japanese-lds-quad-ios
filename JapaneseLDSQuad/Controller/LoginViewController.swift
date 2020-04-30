//
//  LoginViewController.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 3/21/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: MainButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "loginViewTitle".localized
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AuthenticationManager.shared.delegate = self
    }
    
    fileprivate func alert(message: String, close: Bool = false) {
        let title = "loginError".localized
        let alertController = Utilities.shared.alert(view: view, title: title, message: message, handler: nil)
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func presentProfileViewController() {
        if let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.profile) {
            navigationController?.setViewControllers([viewController], animated: false)
        }
    }
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        guard let email = emailTextField.text, !email.isEmpty,
            let password = passwordTextField.text, !password.isEmpty else {
                alert(message: "fillAllFields".localized)
                return
        }
        loginButton.disable()
        AuthenticationManager.shared.signIn(email: email, password: password)
    }
    
    @IBAction func signupButtonTapped(_ sender: Any) {
        if let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.signup) {
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    @IBAction func passwordResetButtonTapped(_ sender: Any) {
        if let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.password) {
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}

extension LoginViewController: AuthenticationManagerDelegate {
    
    func authenticationManagerDidSucceed() {
        loginButton.enable()
        presentProfileViewController()
    }
    
    func authenticationManagerDidReceiveMessage(_ message: String) {
        loginButton.enable()
        alert(message: message)
    }
}
