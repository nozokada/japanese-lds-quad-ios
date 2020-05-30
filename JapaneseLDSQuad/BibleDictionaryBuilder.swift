//
//  BibleDictionaryBuilder.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/6/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import Foundation
import RealmSwift

class BibleDictionaryBuilder: ContentBuilder {
    
    override func buildSearchResultText(scripture: Scripture) -> String {
        let title = scriptures.filter("verse = 'title'").first!.scripture_primary.tagsRemoved
        return "聖句ガイド「\(title)」\(scripture.verse)段落目"
    }
    
    override func buildSearchResultDetailText(scripture: Scripture) -> String {
        return ""
    }
    
    override func buildTitle() -> String {
        var html = ""
        if let title = scriptures.filter("verse = 'title'").first {
            html += "<div class='title'>\(title.scripture_primary)</div>"
        }
        return html
    }

    override func buildBody() -> String {
        var html = ""
        let verse = ""
        for scripture in scriptures {
            if scripture.id.count != 6 {
                continue
            }
            let targeted = scripture.verse == targetVerse
            html += """
            \(targeted ? "<a id='anchor'></a>" : "")
            <div id='\(scripture.id)' class='\(targeted ? "targeted " : "")'>
              <div class='verse-container'>
                <div class='verse'>
                  <a class='verse-number' href='\(scripture.id)/\(Constants.AnnotationType.bookmark)'>\(verse)</a>
                  <span lang='\(Constants.Lang.primary)'>\(scripture.scripture_primary)</span>
                </div>
              </div>
            </div>
            """
        }
        return html
    }
}
