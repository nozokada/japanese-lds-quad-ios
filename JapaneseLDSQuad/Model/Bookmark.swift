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
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
