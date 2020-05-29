//
//  MainTextField.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 5/28/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit

class MainTextField: UITextField {

    override func awakeFromNib() {
        super.awakeFromNib()
        customizeViews()
    }
    
    func customizeViews() {
        let nightModeEnabled = Utilities.shared.nightModeEnabled
        textColor = Utilities.shared.getTextColor()
        tintColor = nightModeEnabled ? UIColor.gray : UIColor.darkGray
        backgroundColor = nightModeEnabled ? UIColor.darkGray : UIColor.white
        let placeholderColor = nightModeEnabled
            ? UIColor.gray : UIColor.lightGray
        attributedPlaceholder =  NSAttributedString(
            string: placeholder ?? "",
            attributes: [NSAttributedString.Key.foregroundColor: placeholderColor])
    }
}
