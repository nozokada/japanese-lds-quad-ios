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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !AuthenticationManager.shared.isAutheticated {
            presentLoginViewController()
        }
    }
    
    fileprivate func presentLoginViewController() {
        if let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.login) {
            navigationController?.setViewControllers([viewController], animated: false)
        }
    }
    
    @IBAction func logoutButtonTapped(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            presentLoginViewController()
        }
        catch let error as NSError {
            debugPrint(error.localizedDescription)
        }
    }
}
