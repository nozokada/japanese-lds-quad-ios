//
//  HighlightCell.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/16/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit

class HighlightCell: UICollectionViewCell {
    
    @IBOutlet weak var noteTextLabel: MainTextLabel!
    @IBOutlet weak var highlightedTextLabel: MainTextLabel!
    @IBOutlet weak var nameLabel: MainTextLabel!
    
    func customizeViews() {
        layer.cornerRadius = 5
        layer.borderWidth = 1.0
        layer.borderColor = UserDefaults.standard.bool(forKey: Constants.Config.night)
            ? UIColor.darkGray.cgColor
            : UIColor.lightGray.cgColor
    }
    
    func update(highlight: HighlightedText) {
        customizeViews()
        noteTextLabel.customizeViews()
        highlightedTextLabel.customizeViews()
        nameLabel.customizeViews()
        
        nameLabel.text = Locale.current.languageCode == Constants.LanguageCode.primary
            ? "\(highlight.name_primary)"
            : "\(highlight.name_secondary)"
        highlightedTextLabel.text = highlight.text
        
        if highlight.note.isEmpty {
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("yMMMdE jms")
            noteTextLabel.text = Locale.current.languageCode == Constants.LanguageCode.primary ?
                "\(formatter.string(from: highlight.date as Date))のハイライト" : "Created on \(formatter.string(from: highlight.date as Date))"
        } else {
            noteTextLabel.text = highlight.note
        }
    }
}
