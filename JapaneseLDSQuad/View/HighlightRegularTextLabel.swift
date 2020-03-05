//
//  MainTextLabel.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/17/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit

class HighlightRegularTextLabel: UILabel {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        customizeViews()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        customizeViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func customizeViews() {
        numberOfLines = 0
        lineBreakMode = .byWordWrapping
        font = Utilities.shared.getFont()
        textColor = Utilities.shared.getTextColor()
    }
    
    func update(text: String) {
        customizeViews()
        self.text = text
    }
}
