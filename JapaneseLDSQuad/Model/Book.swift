//
//  Book.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/3/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import Foundation
import RealmSwift

class Book: Object {
    
    @objc dynamic var id = ""
    @objc dynamic var name_primary = ""
    @objc dynamic var name_secondary = ""
    @objc dynamic var link = ""
    @objc dynamic var parent_book: Book!
    
    let child_books = LinkingObjects(fromType: Book.self, property: "parent_book")
    let child_scriptures = LinkingObjects(fromType: Scripture.self, property: "parent_book")
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
