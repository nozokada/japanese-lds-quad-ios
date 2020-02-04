//
//  MainNavigationController.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/3/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit

class MainNavigationController: UINavigationController {

    var previousNavigationController: UINavigationController?
    var isSearchNavigationController = false
    var isPassageLookupNavigationController = false

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
