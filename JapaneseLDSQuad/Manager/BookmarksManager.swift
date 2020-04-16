//
//  BookmarkManager.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/4/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit
import RealmSwift

class BookmarksManager {
    
    static let shared = BookmarksManager()
    
    lazy var realm = try! Realm()
    
    func exists(scriptureId: String) -> Bookmark? {
        return realm.object(ofType: Bookmark.self, forPrimaryKey: scriptureId)
    }
    
    func add(scriptureId: String, createdAt: NSDate = NSDate()) -> Bookmark? {
        if let _ = exists(scriptureId: scriptureId) {
            print("Bookmark \(scriptureId) already exists")
            return nil
        }
        
        guard let scripture = Utilities.shared.getScripture(id: scriptureId) else {
            return nil
        }
        let bookmarkToAdd = Bookmark(
            id: scripture.id,
            namePrimary: Utilities.shared.generateTitlePrimary(scripture: scripture),
            nameSecondary: Utilities.shared.generateTitleSecondary(scripture: scripture),
            scripture: scripture,
            date: createdAt
        )
        try! realm.write {
            realm.add(bookmarkToAdd)
        }
        #if DEBUG
        print("Added bookmark for scripture \(scriptureId) successfully")
        #endif
        return bookmarkToAdd
    }
    
    func delete(bookmarkId: String) -> Bool {
        guard let bookmarkToRemove = exists(scriptureId: bookmarkId) else {
            print("Bookmark \(bookmarkId) was already removed")
            return false
        }
        
        try! realm.write {
            realm.delete(bookmarkToRemove)
        }
        #if DEBUG
        print("Deleted bookmark \(bookmarkId) successfully")
        #endif
        return true
    }
    
    func update(id: String) {
        if delete(bookmarkId: id) {
            FirestoreManager.shared.deleteBookmark(id: id)
            return
        }
        if let bookmark = add(scriptureId: id) {
            FirestoreManager.shared.addBookmark(bookmark)
        }
    }
}
