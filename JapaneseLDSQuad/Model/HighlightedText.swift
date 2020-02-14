//
//  HighlightedText.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/3/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import Foundation
import RealmSwift

class HighlightedText: Object {
    
    @objc dynamic var id = ""
    @objc dynamic var name_primary = ""
    @objc dynamic var name_secondary = ""
    @objc dynamic var text = ""
    @objc dynamic var note = ""
    @objc dynamic var highlighted_scripture: HighlightedScripture!
    @objc dynamic var date: NSDate!
    
    convenience init(id: String, namePrimary: String, nameSecondary: String, text: String, note: String, highlightedScripture: HighlightedScripture, date: NSDate) {
        self.init()
        self.id = id
        self.name_primary = namePrimary
        self.name_secondary = nameSecondary
        self.text = text
        self.note = note
        self.highlighted_scripture = highlightedScripture
        self.date = date
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
