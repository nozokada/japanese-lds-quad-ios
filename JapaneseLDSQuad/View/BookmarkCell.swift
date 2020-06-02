//
//  BookmarkViewCell.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 6/1/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit

class BookmarkCell: UITableViewCell {

    @IBOutlet weak var primaryTitleTextLabel: UILabel!
    @IBOutlet weak var secondaryTitleTextLabel: UILabel!
    @IBOutlet weak var dateTextLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        customizeViews()
    }
    
    func customizeViews() {
        backgroundColor = Utilities.shared.getCellColor()
    }
    
    func update(bookmark: Bookmark) {
        customizeViews()
        
        primaryTitleTextLabel?.text = bookmark.name_primary
        primaryTitleTextLabel?.font = Utilities.shared.getFont()
        primaryTitleTextLabel?.textColor = Utilities.shared.getTextColor()
        primaryTitleTextLabel?.numberOfLines = 0
        
        if Utilities.shared.dualEnabled {
            secondaryTitleTextLabel?.text = bookmark.name_secondary
            secondaryTitleTextLabel?.font = Utilities.shared.getFont(multiplySizeBy: 0.6)
            secondaryTitleTextLabel?.textColor = .gray
            secondaryTitleTextLabel?.numberOfLines = 0
        }
        
        dateTextLabel.text = Utilities.shared.formatDate(date: bookmark.date as Date)
        dateTextLabel.font = Utilities.shared.getFont(multiplySizeBy: 0.6)
        dateTextLabel.textColor = .gray
        dateTextLabel.numberOfLines = 0
    }
}
