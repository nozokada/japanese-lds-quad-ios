//
//  MainButton.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/21/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit

@IBDesignable
class MainButton: UIButton {

    let cornerRadius: CGFloat = 5

    override func awakeFromNib() {
        super.awakeFromNib()
        customizeView()
    }
    
    override func prepareForInterfaceBuilder() {
        customizeView()
    }
    
    func customizeView() {
        layer.cornerRadius = cornerRadius
        backgroundColor = Constants.NavigationBarColor.day
        setTitleColor(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), for: .normal)
    }
    
    func enable() {
        self.alpha = 1.0
        isEnabled = true
    }
    
    func disable() {
        self.alpha = 0.5
        isEnabled = false
    }
}
