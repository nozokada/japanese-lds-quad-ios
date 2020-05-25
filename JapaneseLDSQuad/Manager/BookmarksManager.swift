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
    
    func syncAdd(bookmarkId: String, createdAt: Date) {
        guard let scripture = Utilities.shared.getScripture(id: bookmarkId) else {
            return
        }
        let bookmark = get(bookmarkId: bookmarkId)
            ?? create(scripture: scripture, createdAt: createdAt)
        let localTimestamp = bookmark.date.timeIntervalSince1970
        let serverTimestamp = createdAt.timeIntervalSince1970
        if localTimestamp >= serverTimestamp {
            #if DEBUG
            print("Bookmark \(bookmark.id) already exists in Realm so won't sync")
            #endif
            return
        }
        if localTimestamp < serverTimestamp {
            #if DEBUG
            print("Bookmark \(bookmark.id) is outdated in Realm so syncing")
            #endif
            let _ = delete(bookmark)
        }
        let _ = create(scripture: scripture, createdAt: createdAt)
        DispatchQueue.main.async {
            self.delegate?.updateContentView()
        }
    }
    
    func syncRemove(bookmarkId: String) {
        guard let bookmark = get(bookmarkId: bookmarkId) else {
            #if DEBUG
            print("Bookmark \(bookmarkId) does not exist in Realm")
            #endif
            return
        }
        let _ = delete(bookmark)
        DispatchQueue.main.async {
            self.delegate?.updateContentView()
        }
    }
    
    fileprivate func add(scriptureId: String) {
        guard let scripture = Utilities.shared.getScripture(id: scriptureId) else {
            return
        }
        let bookmark = create(scripture: scripture, createdAt: Date())
        FirestoreManager.shared.addBookmark(bookmark)
    }
    
    fileprivate func remove(bookmarkId: String) -> Bool {
        guard let bookmark = get(bookmarkId: bookmarkId) else {
            #if DEBUG
            print("Bookmark \(bookmarkId) does not exist in Realm")
            #endif
            return false
        }
        let id = delete(bookmark)
        FirestoreManager.shared.removeBookmark(id: id)
        return true
    }
    
    fileprivate func create(scripture: Scripture, createdAt: Date) -> Bookmark {
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
        print("Bookmark \(bookmark.id) was added successfully to Realm")
        #endif
        return bookmark
    }
    
    fileprivate func delete(_ bookmark: Bookmark) -> String {
        let id = bookmark.id
        try! realm.write {
            realm.delete(bookmark)
        }
        #if DEBUG
        print("Bookmark \(id) was deleted successfully from Realm")
        #endif
        return id
    }
}
