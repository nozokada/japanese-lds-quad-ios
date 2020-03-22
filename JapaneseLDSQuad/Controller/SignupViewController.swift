//
//  SignupViewController.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 3/22/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit

class SignupViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "signupViewTitle".localized
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        navigationController?.popToRootViewController(animated: true)
    }
}
