//
//  SignInViewController.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 3/21/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit
import FirebaseAuth

class SignInViewController: UIViewController {

    @IBOutlet weak var messageTextLabel: UILabel!
    @IBOutlet weak var emailTextField: MainTextField!
    @IBOutlet weak var passwordTextField: MainPasswordTextField!
    @IBOutlet weak var signInButton: MainButton!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var passwordResetButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "signInViewTitle".localized
        messageTextLabel.text = "signInDescriptionLabel".localized
        emailTextField.placeholder = "emailPlaceholder".localized
        passwordTextField.placeholder = "passwordPlaceholder".localized
        signInButton.setTitle("signInButtonLabel".localized, for: .normal)
        registerButton.setTitle("registerButtonLabel".localized, for: .normal)
        passwordResetButton.setTitle("passwordResetLabel".localized, for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AuthenticationManager.shared.delegate = self
        messageTextLabel.textColor = Utilities.shared.getTextColor()
        view.backgroundColor = Utilities.shared.getBackgroundColor()
        emailTextField.customizeViews()
        passwordTextField.customizeViews()
    }
    
    fileprivate func alert(title: String, message: String, close: Bool = false) {
        let alertController = Utilities.shared.alert(view: view, title: title, message: message, handler: nil)
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func presentAccountViewController() {
        guard let viewController = storyboard?.instantiateViewController(
            withIdentifier: Constants.StoryBoardID.account) else {
                return
        }
        navigationController?.setViewControllers([viewController], animated: false)
    }
    
    @IBAction func signInButtonTapped(_ sender: Any) {
        guard let email = emailTextField.text, !email.isEmpty,
            let password = passwordTextField.text, !password.isEmpty else {
                alert(title: "signInError".localized, message: "fillAllFields".localized)
                return
        }
        signInButton.disable()
        signInButton.showSpinner()
        AuthenticationManager.shared.signIn(email: email, password: password)
    }
    
    @IBAction func registerButtonTapped(_ sender: Any) {
        guard let viewController = storyboard?.instantiateViewController(
            withIdentifier: Constants.StoryBoardID.register) else {
                return
        }
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    @IBAction func passwordResetButtonTapped(_ sender: Any) {
        guard let viewController = storyboard?.instantiateViewController(
            withIdentifier: Constants.StoryBoardID.password) else {
                return
        }
        navigationController?.pushViewController(viewController, animated: true)
    }
}

extension SignInViewController: AuthenticationManagerDelegate {
    
    func authenticationManagerDidSucceed() {
        signInButton.hideSpinner()
        signInButton.enable()
        presentAccountViewController()
    }
    
    func authenticationManagerDidReceiveMessage(_ message: String) {
        signInButton.hideSpinner()
        signInButton.enable()
        alert(title: "signInError".localized, message: message)
    }
}
