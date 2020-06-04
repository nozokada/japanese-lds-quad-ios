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
    
    var originalText: String?
    var spinner: MainIndicatorView?

    override func awakeFromNib() {
        super.awakeFromNib()
        customizeView()
    }
    
    override func prepareForInterfaceBuilder() {
        customizeView()
    }
    
    func customizeView() {
        layer.cornerRadius = 5
        backgroundColor = Constants.NavigationBarColor.day
        setTitleColor(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), for: .normal)
    }
    
    func enable() {
        self.alpha = 1.0
        isEnabled = true
        hideSpinner()
    }
    
    func disable() {
        self.alpha = 0.5
        isEnabled = false
        showSpinner()
    }
    
    func showSpinner() {
        originalText = titleLabel?.text
        setTitle("", for: .normal)
        if spinner == nil {
            spinner = MainIndicatorView(parentView: self)
        }
        spinner?.startAnimating()
    }
    
    func hideSpinner() {
        if originalText != nil {
            setTitle(originalText, for: .normal)
        }
        spinner?.stopAnimating()
    }
}
