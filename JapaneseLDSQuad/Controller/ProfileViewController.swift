//
//  ProfileViewController.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 3/17/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit
import Firebase

class ProfileViewController: UIViewController {

    @IBOutlet weak var logoutButton: MainButton!
    
    var user: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let user = AuthenticationManager.shared.currentUser else {
            presentLoginViewController()
            return
        }
        self.user = user
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AuthenticationManager.shared.delegate = self
    }
    
    fileprivate func alert(message: String, close: Bool = false) {
        let title = "logoutError".localized
        let alertController = Utilities.shared.alert(view: view, title: title, message: message, handler: nil)
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func presentLoginViewController() {
        if let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.login) {
            navigationController?.setViewControllers([viewController], animated: false)
        }
    }
    
    @IBAction func logoutButtonTapped(_ sender: Any) {
        AuthenticationManager.shared.signOut(completion: self.presentLoginViewController)
    }
}

extension ProfileViewController: AuthenticationManagerDelegate {
    
    func authenticationManagerDidSucceed() {
    }
    
    func authenticationManagerDidReceiveMessage(_ message: String) {
        alert(message: message)
    }
}
