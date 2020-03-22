//
//  ProfileViewController.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 3/17/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !AuthenticationManager.shared.isAutheticated {
            if let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.login) {
                navigationController?.viewControllers = [viewController]
            }
        }
    }
}
