//
//  ContentBuilder.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/6/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import Foundation
import RealmSwift

class ContentBuilder {
    
    var realm: Realm
    var dualEnabled: Bool
    var scriptures: Results<Scripture>
    var numbered: Bool
    var targetVerse: String?
    
    init(scriptures: Results<Scripture>, numbered: Bool = false) {
        realm = try! Realm()
        self.scriptures = scriptures
        self.numbered = numbered
        dualEnabled = Utilities.shared.dualEnabled
    }
    
    func buildSearchResultText(scripture: Scripture) -> String {
        if scripture.parent_book.link.hasPrefix("jst") {
            let title = scriptures.filter("verse = 'title'").first!.scripture_primary.tagsRemoved.verseAfterColonRemoved
             return "\(title) : \(scripture.verse)"
        }
        return numbered
            ? "\(scripture.parent_book.name_primary) \(scripture.chapter) : \(scripture.verse)"
            : "\(scripture.parent_book.parent_book.name_primary) \(scripture.parent_book.name_primary) \(scripture.verse)段落目"
    }
    
    func buildSearchResultDetailText(scripture: Scripture) -> String {
        if scripture.parent_book.link.hasPrefix("jst") {
            let title = scriptures.filter("verse = 'title'").first!.scripture_secondary.tagsRemoved.verseAfterColonRemoved
            return "\(title) : \(scripture.verse)"
        }
        return numbered
            ? "\(scripture.parent_book.name_secondary) \(scripture.chapter) : \(scripture.verse)"
            : "\(scripture.parent_book.parent_book.name_secondary) \(scripture.parent_book.name_secondary) Paragraph \(scripture.verse)"
    }
    
    func buildContent(targetVerse: String?) -> String {
        self.targetVerse = targetVerse
        return buildCSS() + buildTitle() + buildPrefaces() + buildBody()
    }
    
    func buildTitle() -> String {
        var html = ""
        if let title = scriptures.filter("verse = 'title'").first {
            html += "<div class='title primary'>\(title.scripture_primary)</div>"
            html += "<div class='title secondary'>\(title.scripture_secondary)</div>"
        }
        if let counter = scriptures.filter("verse = 'counter'").first {
            html += "<div class='subtitle primary'>\(counter.scripture_primary)</div>"
            html += "<div class='subtitle secondary'>\(counter.scripture_secondary)</div>"
        }
        return html
    }
    
    func buildPrefaces() -> String {
        var html = ""
        if let preface = scriptures.filter("verse = 'preface'").first {
            html += "<hr class='secondary'>"
            html += "<div class='paragraph primary'>\(preface.scripture_primary)</div>"
            html += "<div class='paragraph secondary'>\(preface.scripture_secondary)</div>"
        }
        
        if let intro = scriptures.filter("verse = 'intro'").first {
            html += "<hr class='secondary'>"
            html += "<div class='paragraph primary'>\(intro.scripture_primary)</div>"
            html += "<div class='paragraph secondary'>\(intro.scripture_secondary)</div>"
        }
        
        if let summary = scriptures.filter("verse = 'summary'").first {
            html += "<hr class='secondary'>"
            html += "<div class='paragraph primary'><i>\(summary.scripture_primary)</i></div>"
            html += "<div class='paragraph secondary'><i>\(summary.scripture_secondary)</i></div>"
        }
        return html
    }
    
    func buildBody() -> String {
        var html = ""
        for scripture in scriptures {
            let verseNumber = numbered ? scripture.verse : ""
            if scripture.id.count == 6 {
                let targeted = scripture.verse == targetVerse
                let bookmarked = BookmarksManager.shared.get(bookmarkId: scripture.id) != nil ? true : false
                if targeted { html += "<a id='anchor'></a>" }
                html += "<hr class='secondary'>"
                html += "<div id='\(scripture.id)' class='"
                html += targeted ? "targeted " : ""
                html += bookmarked ? "bookmarked" : ""
                html += "'>"
                html += "<div class='verse primary'><a class='verse-number' href='\(scripture.id)/\(Constants.AnnotationType.bookmark)'>\(verseNumber)</a> <span lang='\(Constants.Language.primary)'>\(scripture.scripture_primary)</span></div>"
                if !scripture.scripture_secondary.isEmpty {
                    html += "<div class='verse secondary'><a class='verse-number' href='\(scripture.id)/\(Constants.AnnotationType.bookmark)'>\(verseNumber)</a> <span lang='\(Constants.Language.secondary)'>\(scripture.scripture_secondary)</span></div>"
                }
                html += "</div>"
            }
        }
        return html
    }
    
    fileprivate func buildCSS() -> String {
        let font = Utilities.shared.getCSSFont()
        let fontSize = Utilities.shared.fontSizeMultiplier
        let fontColor = Utilities.shared.getCSSTextColor()
        let backgroundColor = Utilities.shared.getCSSBackgroundColor()
        
        let screenScale = Int(UIScreen.main.scale)
        let bookmarkImageFileName = screenScale > 1 ? "Bookmark Verse@\(screenScale)x" : "Bookmark Verse"
        
        let image = "<img src='Images/\(bookmarkImageFileName).png' hidden>"
        
        let headings =
            """
            .title {
                text-align: center;
                text-transform: uppercase;
                margin-bottom: 15px;
                margin-top: 10px;
            }
            .hymn-title {
                text-align: center;
                margin-bottom: 15px;
                margin-top: 10px;
            }
            .subtitle {
                text-align: center;
                margin-bottom: 15px;
            }
            """
        
        let body =
            """
            body,tr {
                margin: 0;
                padding: 0.5em;
                font-family: '\(font)';
                line-height: 1.4;
                font-size: \(fontSize)em;
                color: \(fontColor);
                background-color: \(backgroundColor);
                -webkit-text-size-adjust: none;
            }
            """
        
        let verse =
            """
            .verse {
                padding: 0.5em;
            }
            .verse.side {
                display: table-cell;
                width: 50%;
            }
            """
        
        let verseNumber =
            """
            .verse-number {
                color: \(fontColor);
                text-decoration: underline;
                font-weight: bold;
            }
            """
        
        let bookmarked =
            """
            .bookmarked:before {
                background-image: url('Images/\(bookmarkImageFileName).png');
                background-size: 1em 0.5em;
                display: inline-block;
                width: 1em;
                height: 0.5em;
                position: absolute;
                left: 0;
                content: '';
            }
            """
        
        let paragraph =
            """
            .paragraph {
                padding: 0.5em;
            }
            .paragraph.side {
                display: table-cell;
                width: 50%;
            }
            """
        
        let hymnVerse =
            """
            .hymn-verse {
                padding: 0.5em;
            }
            .hymn-verse.side {
                display: table-cell;
                width: 50%;
            }
            .hymn-verse ol {
                margin: 0 auto;
                width: 80%;
            }
            """
        
        let large =
            """
            .large {
                font-size: 160%;
            }
            """
        
        let mark =
            """
            mark {
                background-color: rgb(251,240,189);
            }
            """
        
        let head =
            """
            <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=2.0, user-scalable=yes' />
            <head>
                \(image)
                <style type='text/css'>
                    \(headings)
                    \(body)
                    \(verse)
                    \(hymnVerse)
                    \(verseNumber)
                    \(bookmarked)
                    \(paragraph)
                    \(large)
                    \(mark)
                </style>
            </head>
            """
        
        return head;
    }
}
