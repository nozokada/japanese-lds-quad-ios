//
//  ScriptureBuilder.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/6/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import Foundation
import RealmSwift

class ScriptureBuilder: ContentBuilder {
    var realm: Realm
    var scriptures: Results<Scripture>
    var targetVerse = ""
    var showVerseNumber = true
    
    init(scriptures: Results<Scripture>, targetVerse: String, showVerseNumber: Bool) {
        realm = try! Realm()
        self.scriptures = scriptures
        self.targetVerse = targetVerse
        self.showVerseNumber = showVerseNumber
    }
    
    func buildTitle() -> String {
        var html = ""
        if let title = scriptures.filter("verse = 'title'").first {
            html += "<div class='title'>\(title.scripture_primary)</div>"
            if dualEnabled {
                html += "<div class='title'>\(title.scripture_secondary)</div>"
            }
        }
        if let counter = scriptures.filter("verse = 'counter'").first {
            html += "<div class='subtitle'>\(counter.scripture_primary)</div>"
            html += dualEnabled ? "<div class='subtitle'>\(counter.scripture_secondary)</div>" : ""
        }
        return html
    }
    
    func buildBody() -> String {
        var html = ""
        for scripture in scriptures {
            let verse = showVerseNumber ? scripture.verse : ""
            
            if scripture.id.count == 6 {
                if scripture.verse == targetVerse {
                    html += "<a id='anchor'></a>"
                }
                let bookmarked = realm.objects(Bookmark.self).filter("id = '\(scripture.id)'").first != nil ? true : false
                
                if dualEnabled && !scripture.scripture_secondary.isEmpty {
                    html += "<hr>"
                    html += "<div id='\(scripture.id)'"
                    html += bookmarked ? " class='bookmarked'>" : ">"
                    html += "<div class='verse'><a class='verse-number' href='\(scripture.id)/bookmark'>\(verse)</a> <span lang='\(Constants.LanguageCode.primary)'>\(scripture.scripture_primary)</span></div>"
                    html += "<div class='verse'><a class='verse-number' href='\(scripture.id)/bookmark'>\(verse)</a> <span lang='\(Constants.LanguageCode.secondary)'>\(scripture.scripture_secondary)</span></div>"
                }
                else {
                    html += "<div id='\(scripture.id)'"
                    html += bookmarked ? " class='bookmarked'>" : ">"
                    let primaryScripture = scripture.scripture_primary
                    html += "<div class='verse'><a class='verse-number' href='\(scripture.id)/bookmark'>\(verse)</a> <span lang='\(Constants.LanguageCode.primary)'>\(primaryScripture)</span></div>"

                }
                html += "</div>"
            }
        }
        return html
    }
}
