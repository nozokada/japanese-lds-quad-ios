//
//  AnnotationManager.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/4/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import RealmSwift

class AnnotationManager {
    
    let realm: Realm = try! Realm()
    
    func getScripture(verseId: String) -> Scripture? {
        if let scripture = realm.objects(Scripture.self).filter("id = '\(verseId)'").first {
            return scripture
        }
        return nil
    }
    
    func generateTitlePrimary(scripture: Scripture) -> String {
        if scripture.parent_book.link.hasPrefix("gs") || scripture.parent_book.link.hasPrefix("jst") {
            if let title = getScripture(verseId: "\(scripture.id.prefix(4))title") {
                return "\(title.scripture_primary.replacingOccurrences(of: Constants.RegexPattern.tags, with: "", options: .regularExpression).replacingOccurrences(of: "：.*", with: "", options: .regularExpression)) : \(scripture.verse)"
            }
        }
        return "\(scripture.parent_book.name_primary) \(scripture.chapter) : \(scripture.verse)"
    }
    
    func generateTitleSecondary(scripture: Scripture) -> String {
        if scripture.parent_book.link.hasPrefix("gs") || scripture.parent_book.link.hasPrefix("jst") {
            if let title = getScripture(verseId: "\(scripture.id.prefix(4))title") {
                let titleSecondary = title.scripture_secondary.isEmpty ? title.scripture_primary : title.scripture_secondary
                return "\(titleSecondary.replacingOccurrences(of: Constants.RegexPattern.tags, with: "", options: .regularExpression).replacingOccurrences(of: ":.*", with: "", options: .regularExpression)) : \(scripture.verse)"
            }
        }
        return "\(scripture.parent_book.name_secondary) \(scripture.chapter) : \(scripture.verse)"
    }
}
