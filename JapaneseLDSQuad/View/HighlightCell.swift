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
    @IBOutlet weak var nameLabel: MainTextLabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        customizeViews()
    }
    
    func customizeViews() {
        layer.cornerRadius = 15
        layer.borderWidth = 1.0
        layer.borderColor = UserDefaults.standard.bool(forKey: Constants.Config.night)
            ? Constants.FontColor.night.cgColor
            : Constants.FontColor.day.cgColor
    }
    
    func update(highlight: HighlightedText) {
        customizeViews()
        noteTextLabel.customizeViews()
        nameLabel.customizeViews()
        
        if highlight.note.isEmpty {
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("yMMMdE jms")
            noteTextLabel.text = Locale.current.languageCode == Constants.LanguageCode.primary ?
                "\(formatter.string(from: highlight.date as Date))のハイライト" : "Created on \(formatter.string(from: highlight.date as Date))"
        } else {
            noteTextLabel.text = highlight.note
        }
        nameLabel.text = Locale.current.languageCode == Constants.LanguageCode.primary
            ? "\(highlight.name_primary)\n\(highlight.text)"
            : "\(highlight.name_secondary)\n\(highlight.text)"
    }
}
