//
//  HymnBuilder.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/6/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import Foundation
import RealmSwift

class HymnBuilder: ContentBuilder {
    var realm: Realm
    var scriptures: Results<Scripture>
    var targetVerse = ""

    init(scriptures: Results<Scripture>, targetVerse: String) {
        realm = try! Realm()
        self.scriptures = scriptures
        self.targetVerse = targetVerse
    }
    
    func buildTitle() -> String {
        var html = ""
        if let title = scriptures.filter("verse = 'title'").first {
            html += "<div class='title'>\(title.scripture_primary)</div>"
            if dualEnabled {
                html += "<div class='hymn-title'>\(title.scripture_secondary)</div>"
            }
        }
        return html
    }
    
    func buildBody() -> String {
        var html = ""
        for scripture in scriptures {
            if scripture.id.count == 6 {
                if scripture.verse == targetVerse {
                    html += "<a id='anchor'></a>"
                }
                let bookmarked = realm.objects(Bookmark.self).filter("id = '\(scripture.id)'").first != nil ? true : false
                
                if dualEnabled && !scripture.scripture_secondary.isEmpty {
                    html += "<hr>"
                    html += "<div id='\(scripture.id)'"
                    html += bookmarked ? " class='bookmarked'>" : ">"
                    html += "<div class='hymn-verse'><ol><span lang='\(Constants.LanguageCode.primary)'>\(scripture.scripture_primary)</span></ol></div>"
                    html += "<div class='hymn-verse'><ol><span lang='\(Constants.LanguageCode.secondary)'>\(scripture.scripture_secondary)</span></ol></div>"
                }
                else {
                    html += "<div id='\(scripture.id)'"
                    html += bookmarked ? " class='bookmarked'>" : ">"
                    let primaryScripture = scripture.scripture_primary
                    html += "<div class='hymn-verse'><ol><span lang='\(Constants.LanguageCode.primary)'>\(primaryScripture)</span></ol></div>"
                }
                html += "</div>"
            }
        }
        return html
    }
}
