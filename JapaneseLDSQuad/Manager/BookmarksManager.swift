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
    
    func get(bookmarkId: String) -> Bookmark? {
        return realm.object(ofType: Bookmark.self, forPrimaryKey: bookmarkId)
    }
    
    func getAll(sortBy: String = "date", ascending: Bool = false) -> Results<Bookmark> {
        return realm.objects(Bookmark.self).sorted(byKeyPath: sortBy, ascending: ascending)
    }
    
    func add(scriptureId: String, createdAt: Date = Date(), completion: ((Bookmark) -> ())? = nil) {
        guard let scripture = Utilities.shared.getScripture(id: scriptureId) else {
            return
        }
        if let bookmark = Utilities.shared.getBookmark(id: scriptureId) {
            if bookmark.date as Date >= createdAt {
                print("Bookmark \(bookmark.id) already exists")
                return
            }
            let _ = delete(bookmarkId: bookmark.id)
        }
        let bookmarkToAdd = Bookmark(
            id: scripture.id,
            namePrimary: Utilities.shared.generateTitlePrimary(scripture: scripture),
            nameSecondary: Utilities.shared.generateTitleSecondary(scripture: scripture),
            scripture: scripture,
            date: createdAt as NSDate
        )
        try! realm.write {
            realm.add(bookmarkToAdd)
        }
        #if DEBUG
        print("Bookmark \(scriptureId) was added successfully")
        #endif
        completion?(bookmarkToAdd)
    }
    
    func delete(bookmarkId: String, completion: ((String) -> ())? = nil) -> Bool {
        guard let bookmarkToRemove = get(bookmarkId: bookmarkId) else {
            print("Bookmark \(bookmarkId) was already deleted")
            return false
        }
        try! realm.write {
            realm.delete(bookmarkToRemove)
        }
        #if DEBUG
        print("Bookmark \(bookmarkId) was deleted successfully")
        #endif
        completion?(bookmarkId)
        return true
    }
    
    func update(id: String) {
        if !delete(bookmarkId: id, completion: FirestoreManager.shared.deleteBookmark) {
            add(scriptureId: id, completion:FirestoreManager.shared.addBookmark)
        }
    }
}
