//
//  MainIndicatorView.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/4/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit

class MainIndicatorView: UIActivityIndicatorView {

    init(parentView: UIView) {
        super.init(frame: CGRect.zero)
        center = CGPoint(x: parentView.frame.width / 2 - frame.width / 2, y: parentView.frame.height / 2 - frame.height / 2)
        style = .white
        parentView.addSubview(self)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
