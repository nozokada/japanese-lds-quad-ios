//
//  BookmarksManager.swift
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
    
    func update(id: String) {
        if !remove(bookmarkId: id) {
            add(scriptureId: id)
        }
    }
    
    func get(bookmarkId: String) -> Bookmark? {
        return realm.object(ofType: Bookmark.self, forPrimaryKey: bookmarkId)
    }
    
    func getAll(sortBy: String = "date", ascending: Bool = false) -> Results<Bookmark> {
        return realm.objects(Bookmark.self).sorted(byKeyPath: sortBy, ascending: ascending)
    }
    
    func syncAdd(scriptureId: String, createdAt: Date) {
        guard let scripture = Utilities.shared.getScripture(id: scriptureId) else {
            return
        }
        if let bookmark = get(bookmarkId: scriptureId) {
            if bookmark.date.timeIntervalSince1970 >= createdAt.timeIntervalSince1970 {
                #if DEBUG
                print("Bookmark \(bookmark.name_primary) (\(bookmark.id)) already exists")
                #endif
                return
            }
            delete(bookmark)
        }
        create(scripture: scripture, createdAt: createdAt)
    }
    
    func syncRemove(bookmarkId: String) {
        guard let bookmark = get(bookmarkId: bookmarkId) else {
            #if DEBUG
            print("Bookmark \(bookmarkId) does not exist")
            #endif
            return
        }
        delete(bookmark)
    }
    
    fileprivate func add(scriptureId: String) {
        guard let scripture = Utilities.shared.getScripture(id: scriptureId) else {
            return
        }
        create(scripture: scripture, createdAt: Date(), sync: true)
    }
    
    fileprivate func remove(bookmarkId: String) -> Bool {
        guard let bookmark = get(bookmarkId: bookmarkId) else {
            #if DEBUG
            print("Bookmark \(bookmarkId) does not exist")
            #endif
            return false
        }
        delete(bookmark, sync: true)
        return true
    }
    
    fileprivate func create(scripture: Scripture, createdAt: Date, sync: Bool = false) {
        let bookmark = Bookmark(
            id: scripture.id,
            namePrimary: Utilities.shared.generateTitlePrimary(scripture: scripture),
            nameSecondary: Utilities.shared.generateTitleSecondary(scripture: scripture),
            scripture: scripture,
            date: createdAt as NSDate
        )
        try! realm.write {
            realm.add(bookmark)
        }
        #if DEBUG
        print("Bookmark \(bookmark.name_primary) (\(bookmark.id)) was added successfully")
        #endif
        if sync {
            FirestoreManager.shared.addBookmark(bookmark)
        }
    }
    
    fileprivate func delete(_ bookmark: Bookmark, sync: Bool = false) {
        let id = bookmark.id
        try! realm.write {
            realm.delete(bookmark)
        }
        #if DEBUG
        print("Bookmark \(id) was deleted successfully")
        #endif
        if sync {
            FirestoreManager.shared.removeBookmark(id: bookmark.id)
        }
    }
}
