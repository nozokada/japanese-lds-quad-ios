//
//  HighlitedScripture.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/3/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import Foundation
import RealmSwift

class HighlightedScripture: Object {
    
    @objc dynamic var id = ""
    @objc dynamic var scripture: Scripture!
    @objc dynamic var date: NSDate!
    
    let highlighted_texts = LinkingObjects(fromType: HighlightedText.self, property: "highlighted_scripture")
    
    convenience init(scripture: Scripture, date: NSDate) {
        self.init()
        self.id = scripture.id
        self.scripture = scripture
        self.date = date
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
