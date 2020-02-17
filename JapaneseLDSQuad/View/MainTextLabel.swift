//
//  MainTextLabel.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/17/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit

class MainTextLabel: UILabel {
   
    func customizeViews() {
        let fontName = UserDefaults.standard.bool(forKey: Constants.Config.font)
            ? Constants.Font.min
            : Constants.Font.kaku
        let fontSize = Constants.FontSize.regular * UserDefaults.standard.double(forKey: Constants.Config.size)
        font = UIFont(name: fontName, size: CGFloat(fontSize))
        textColor = UserDefaults.standard.bool(forKey: Constants.Config.night)
            ? Constants.FontColor.night
            : Constants.FontColor.day
   }
}
