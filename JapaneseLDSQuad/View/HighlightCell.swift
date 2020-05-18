//
//  HighlightCell.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/16/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit

class HighlightCell: UICollectionViewCell {
    
    @IBOutlet weak var nameLabel: HighlightRegularTextLabel!
    @IBOutlet weak var noteTextLabel: HighlightRegularTextLabel!
    @IBOutlet weak var highlightedTextLabel: HighlightSmallTextLabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        customizeViews()
    }
    
    func customizeViews() {
        layer.cornerRadius = Constants.Size.highlightCellCornerRadius
        layer.borderWidth = Constants.Size.highlightCellBorderWidth
        layer.borderColor = UIColor.lightGray.cgColor
    }
    
    func update(highlight: HighlightedText) {
        customizeViews()
        nameLabel.update(text: Utilities.shared.getSystemLang() == Constants.Lang.primary
            ? "\(highlight.name_primary)"
            : "\(highlight.name_secondary)"
        )
        noteTextLabel.update(text: highlight.note)
        highlightedTextLabel.update(text: highlight.text)
    }
}
