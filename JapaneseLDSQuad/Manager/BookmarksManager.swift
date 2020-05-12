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
    
    var delegate: ContentChangeDelegate?
    
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
        let bookmark = get(bookmarkId: scriptureId)
            ?? create(scripture: scripture, createdAt: createdAt)
        let localTimestamp = bookmark.date.timeIntervalSince1970
        let serverTimestamp = createdAt.timeIntervalSince1970
        if localTimestamp > serverTimestamp {
            #if DEBUG
            print("Local bookmark \(bookmark.id) (for \(bookmark.name_primary)) is newer")
            #endif
            return
        }
        if localTimestamp < serverTimestamp {
            #if DEBUG
            print("Local bookmark \(bookmark.id) (for \(bookmark.name_primary)) is older, syncing...")
            #endif
            delete(bookmark)
        }
        if get(bookmarkId: bookmark.id) != nil {
            return
        }
        let _ = create(scripture: scripture, createdAt: createdAt)
        DispatchQueue.main.async {
            self.delegate?.updateContentView()
        }
    }
    
    func syncRemove(bookmarkId: String) {
        guard let bookmark = get(bookmarkId: bookmarkId) else {
            #if DEBUG
            print("Bookmark \(bookmarkId) does not exist")
            #endif
            return
        }
        delete(bookmark)
        DispatchQueue.main.async {
            self.delegate?.updateContentView()
        }
    }
    
    fileprivate func add(scriptureId: String) {
        guard let scripture = Utilities.shared.getScripture(id: scriptureId) else {
            return
        }
        let _ = create(scripture: scripture, createdAt: Date(), sync: true)
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
    
    fileprivate func create(scripture: Scripture, createdAt: Date, sync: Bool = false) -> Bookmark {
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
        print("Bookmark \(bookmark.id) (for \(bookmark.name_primary)) was added successfully")
        #endif
        if sync {
            FirestoreManager.shared.addBookmark(bookmark)
        }
        return bookmark
    }
    
    fileprivate func delete(_ bookmark: Bookmark, sync: Bool = false) {
        let id = bookmark.id
        let name = bookmark.name_primary
        try! realm.write {
            realm.delete(bookmark)
        }
        #if DEBUG
        print("Bookmark \(id) (for \(name)) was deleted successfully")
        #endif
        if sync {
            FirestoreManager.shared.removeBookmark(id: id)
        }
    }
}
