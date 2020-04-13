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
    
    fileprivate func presentLoginViewController() {
        if let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.login) {
            navigationController?.setViewControllers([viewController], animated: false)
        }
    }
    
    @IBAction func logoutButtonTapped(_ sender: Any) {
        AuthenticationManager.shared.signOut(completion: self.presentLoginViewController)
    }
}
