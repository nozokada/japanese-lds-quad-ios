//
//  AnnotationManager.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/4/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import RealmSwift

class AnnotationsManager {
    
    let realm: Realm = try! Realm()
    
    func getScripture(id: String) -> Scripture? {
        if let scripture = realm.objects(Scripture.self).filter("id = '\(id)'").first {
            return scripture
        }
        return nil
    }
    
    func generateTitlePrimary(scripture: Scripture) -> String {
        if scripture.parent_book.link.hasPrefix("gs") || scripture.parent_book.link.hasPrefix("jst") {
            if let title = getScripture(id: "\(scripture.id.prefix(4))title") {
                return "\(title.scripture_primary.tagsRemoved.verseAfterColonRemoved) : \(scripture.verse)"
            }
        }
        return "\(scripture.parent_book.name_primary) \(scripture.chapter) : \(scripture.verse)"
    }
    
    func generateTitleSecondary(scripture: Scripture) -> String {
        if scripture.parent_book.link.hasPrefix("gs") || scripture.parent_book.link.hasPrefix("jst") {
            if let title = getScripture(id: "\(scripture.id.prefix(4))title") {
                let titleSecondary = title.scripture_secondary.isEmpty ? title.scripture_primary : title.scripture_secondary
                return "\(titleSecondary.tagsRemoved.verseAfterColonRemoved) : \(scripture.verse)"
            }
        }
        return "\(scripture.parent_book.name_secondary) \(scripture.chapter) : \(scripture.verse)"
    }
}
