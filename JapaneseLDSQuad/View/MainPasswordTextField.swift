//
//  MainPasswordTextField.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 5/28/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit

class MainPasswordTextField: MainTextField {
    
    var eyeButton: UIButton?
    let buttonSize: CGFloat = 50

    override func awakeFromNib() {
        super.awakeFromNib()
        customizeViews()
    }
    
    override func customizeViews() {
        super.customizeViews()
        isSecureTextEntry = true
        eyeButton = UIButton(frame: CGRect(x: 0, y: 0, width: buttonSize, height: frame.height))
        eyeButton?.setImage(#imageLiteral(resourceName: "Eye"), for: .normal)
        eyeButton?.addTarget(self, action: #selector(toggle), for: .touchUpInside)
        rightView = eyeButton
        rightViewMode = .always
    }
    
    @objc func toggle() {
        isSecureTextEntry = !isSecureTextEntry
        eyeButton?.setImage(isSecureTextEntry ? #imageLiteral(resourceName: "Eye") : #imageLiteral(resourceName: "EyeSlash"), for: .normal)
    }
    
    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: bounds.width - buttonSize, y: 0, width: buttonSize, height: bounds.height)
    }
}
