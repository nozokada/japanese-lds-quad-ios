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
    
    override func buildSearchResultText(scripture: Scripture) -> String {
        let title = scriptures.filter("verse = 'title'").first!.scripture_primary.tagsRemoved
        let counter = scriptures.filter("verse = 'counter'").first!.scripture_primary
        return "賛美歌 \(counter) \(title) \(scripture.verse)番"
    }
    
    override func buildSearchResultDetailText(scripture: Scripture) -> String {
        let title = scriptures.filter("verse = 'title'").first!.scripture_secondary.tagsRemoved
        let counter = scriptures.filter("verse = 'counter'").first!.scripture_secondary
        return "HYMN \(counter) \(title) Verse \(scripture.verse)"
    }
    
    override func buildTitle() -> String {
        var html = ""
        if let title = scriptures.filter("verse = 'title'").first {
            html += "<div class='title'>\(title.scripture_primary)</div>"
            html += "<div class='hymn-title secondary'>\(title.scripture_secondary)</div>"
        }
        return html
    }
    
    override func buildBody() -> String {
        var html = ""
        scriptures.forEach { scripture in
            if scripture.id.count == 6 {
                let targeted = scripture.verse == targetVerse
                if targeted { html += "<a id='anchor'></a>" }
                html += "<hr class='secondary'>"
                html += "<div id='\(scripture.id)' class='"
                html += targeted ? "targeted " : ""
                html += "'>"
                html += "<div class='hymn-verse primary'><ol><span lang='\(Constants.Lang.primary)'>\(scripture.scripture_primary)</span></ol></div>"
                if !scripture.scripture_secondary.isEmpty {
                    html += "<div class='hymn-verse secondary'><ol><span lang='\(Constants.Lang.secondary)'>\(scripture.scripture_secondary)</span></ol></div>"
                }
                html += "</div>"
            }
        }
        return html
    }
}
