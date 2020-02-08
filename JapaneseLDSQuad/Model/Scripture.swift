//
//  Scripture.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/3/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import Foundation
import RealmSwift

class Scripture: Object {
    
    @objc dynamic var id = ""
    @objc dynamic var chapter = 0
    @objc dynamic var verse = ""
    @objc dynamic var scripture_primary = ""
    @objc dynamic var scripture_primary_raw = ""
    @objc dynamic var scripture_secondary = ""
    @objc dynamic var scripture_secondary_raw = ""
    @objc dynamic var parent_book: Book!
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
