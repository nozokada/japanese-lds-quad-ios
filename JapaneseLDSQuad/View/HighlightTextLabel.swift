//
//  MainTextLabel.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/17/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit

class HighlightTextLabel: UILabel {
   
    func customizeViews() {
        numberOfLines = 0
        lineBreakMode = .byWordWrapping
        font = AppUtility.shared.getCurrentFont()
        textColor = AppUtility.shared.getCurrentTextColor()
   }
}
