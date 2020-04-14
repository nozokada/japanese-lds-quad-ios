//
//  BookmarkManager.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/4/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit
import RealmSwift

class BookmarksManager: AnnotationsManager {
    
    static let shared = BookmarksManager()
    
    func updateBookmark(id: String) {
        if let scripture = getScripture(id: id) {
            if let bookmarkToRemove = realm.objects(Bookmark.self).filter("id = '\(scripture.id)'").first {
                try! realm.write {
                    realm.delete(bookmarkToRemove)
                    #if Debug
                    debugPrint("Deleted bookmark for scripture \(scripture.id) successfully")
                    #endif
                }
                FirestoreManager.shared.deleteBookmark(bookmarkId: id)
            }
            else {
                let bookmarkToAdd = Bookmark(id: scripture.id,
                                             namePrimary: generateTitlePrimary(scripture: scripture),
                                             nameSecondary: generateTitleSecondary(scripture: scripture),
                                             scripture: scripture,
                                             date: NSDate())
                try! realm.write {
                    realm.add(bookmarkToAdd)
                    #if Debug
                    debugPrint("Added bookmark for scripture \(scripture.id) successfully")
                    #endif
                }
                FirestoreManager.shared.addBookmark(bookmark: bookmarkToAdd)
            }
        }
    }
}
