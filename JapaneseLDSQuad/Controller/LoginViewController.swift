//
//  LoginViewController.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 3/21/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "loginViewTitle".localized
    }
    
    @IBAction func signupButtonTapped(_ sender: Any) {
        if let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.signup) {
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}
