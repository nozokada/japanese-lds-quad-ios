//
//  Bookmark.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/3/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import Foundation
import RealmSwift

class Bookmark: Object {
    
    @objc dynamic var id = ""
    @objc dynamic var name_primary = ""
    @objc dynamic var name_secondary = ""
    @objc dynamic var scripture: Scripture!
    @objc dynamic var date: NSDate!
    
    convenience init(id: String, namePrimary: String, nameSecondary: String, scripture: Scripture, date: NSDate) {
        self.init()
        self.id = id
        self.name_primary = namePrimary
        self.name_secondary = nameSecondary
        self.scripture = scripture
        self.date = date
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
