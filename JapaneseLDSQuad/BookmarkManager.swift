//
//  BookmarkManager.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/4/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit
import RealmSwift

class BookmarkManager: AnnotationManager {
    
    static let shared = BookmarkManager()
    
    func addOrDeleteBookmark(id: String) {
        if let scripture = getScripture(id: id) {
            if let bookmarkToRemove = realm.objects(Bookmark.self).filter("id = '\(scripture.id)'").first {
                try! realm.write {
                    realm.delete(bookmarkToRemove)
                    debugPrint("Deleted bookmark for scripture \(scripture.id) successfully")
                }
            }
            else {
                let bookmarkToAdd = Bookmark()
                bookmarkToAdd.id = scripture.id
                bookmarkToAdd.scripture = scripture
                bookmarkToAdd.date = NSDate()
                bookmarkToAdd.name_primary = generateTitlePrimary(scripture: scripture)
                bookmarkToAdd.name_secondary = generateTitleSecondary(scripture: scripture)
                
                try! realm.write {
                    realm.add(bookmarkToAdd)
                    debugPrint("Added bookmark for scripture \(scripture.id) successfully")
                }
            }
        }
    }
}
