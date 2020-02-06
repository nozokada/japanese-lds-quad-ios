//
//  ContentBuilder.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/3/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit
import RealmSwift

class ContentBuilder: NSObject {
    
    var realm: Realm!
    var scriptures: Results<Scripture>
    var contents = ""
    var targetChapter = 1
    var targetVerse = ""
    var type = (gs: false, hymn: false, scripture: true)
    
    init(scriptures: Results<Scripture>, targetVerse: String, type: (gs: Bool, hymn: Bool, scripture: Bool)) {
        self.scriptures = scriptures
        self.targetVerse = targetVerse
        self.type = type
        realm = try! Realm()
    }
    
    func build() -> String {
        let dualEnabled = UserDefaults.standard.bool(forKey: Constants.Config.dual)
        
        if let title = scriptures.filter("verse = 'title'").first {
            contents += "<div class='title'>\(title.scripture_primary)</div>"
            if dualEnabled {
                contents += type.hymn ?
                    "<div class='hymn-title'>\(title.scripture_secondary)</div>" : "<div class='title'>\(title.scripture_secondary)</div>"
            }
        }
        
        if !type.hymn {
            if let counter = scriptures.filter("verse = 'counter'").first {
                contents += "<div class='subtitle'>\(counter.scripture_primary)</div>"
                contents += dualEnabled ? "<div class='subtitle'>\(counter.scripture_secondary)</div>" : ""
            }
        }
        
        if let preface = scriptures.filter("verse = 'preface'").first {
            if dualEnabled { contents += "<hr>" }
            contents += "<div class='paragraph'>\(preface.scripture_primary)</div>"
            contents += dualEnabled ? "<div class='paragraph'>\(preface.scripture_secondary)</div>" : ""
        }
        
        if let intro = scriptures.filter("verse = 'intro'").first {
            contents += dualEnabled ? "<hr>" : ""
            contents += "<div class='paragraph'>\(intro.scripture_primary)</div>"
            contents += dualEnabled ? "<div class='paragraph'>\(intro.scripture_secondary)</div>" : ""
        }
        
        if let summary = scriptures.filter("verse = 'summary'").first {
            contents += dualEnabled ? "<hr>" : ""
            contents += summary.scripture_primary.isEmpty ? "" : "<div class='paragraph'><i>\(summary.scripture_primary)</i></div>"
            contents += dualEnabled ? "<div class='paragraph'><i>\(summary.scripture_secondary)</i></div>" : ""
        }
        
        for scripture in scriptures {
            let verse = type.scripture ? scripture.verse : ""
            
            if scripture.id.count == 6 {
                if scripture.verse == targetVerse {
                    contents += "<a id='anchor'></a>"
                }
                
                let bookmarked = realm.objects(Bookmark.self).filter("id = '\(scripture.id)'").first != nil ? true : false
                
                if dualEnabled && !scripture.scripture_secondary.isEmpty {
                    contents += "<hr>"
                    contents += "<div id='\(scripture.id)'"
                    contents += bookmarked ? " class='bookmarked'>" : ">"
                    
                    if type.hymn {
                        contents += "<div class='hymn-verse'><ol><span lang='\(Constants.LanguageCode.primary)'>\(scripture.scripture_primary)</span></ol></div>"
                        contents += "<div class='hymn-verse'><ol><span lang='\(Constants.LanguageCode.secondary)'>\(scripture.scripture_secondary)</span></ol></div>"
                    }
                    else {
                        contents += "<div class='verse'><a class='verse-number' href='\(scripture.id)/bookmark'>\(verse)</a> <span lang='\(Constants.LanguageCode.primary)'>\(scripture.scripture_primary)</span></div>"
                        contents += "<div class='verse'><a class='verse-number' href='\(scripture.id)/bookmark'>\(verse)</a> <span lang='\(Constants.LanguageCode.secondary)'>\(scripture.scripture_secondary)</span></div>"
                    }
                }
                else {
                    contents += "<div id='\(scripture.id)'"
                    contents += bookmarked ? " class='bookmarked'>" : ">"
                    
                    let primaryScripture = type.gs && PurchaseManager.shared.isPurchased ?
                        getGSWithBibleLinks(gsString: scripture.scripture_primary) : scripture.scripture_primary

                    contents += type.hymn ?
                        "<div class='hymn-verse'><ol><span lang='\(Constants.LanguageCode.primary)'>\(primaryScripture)</span></ol></div>" :
                        "<div class='verse'><a class='verse-number' href='\(scripture.id)/bookmark'>\(verse)</a> <span lang='\(Constants.LanguageCode.primary)'>\(primaryScripture)</span></div>"

                }
                contents += "</div>"
            }
        }
        return getCSS() + contents
    }
    
    func getGSWithBibleLinks(gsString: String) -> String {
        let regex = try! NSRegularExpression(pattern: Constants.RegexPattern.passage)
        let matchResults = regex.matches(in: gsString, range: NSMakeRange(0, gsString.count))
        var target = gsString as NSString
        var targetOffset = 0
        let titlesWithoutLink = Constants.Dictionary.titlesWithoutLink.sorted(by: {$0.key.count > $1.key.count})
        var prevLinkTitle = ""
        for result in matchResults {
            let range = NSMakeRange(result.range.location + targetOffset, result.range.length)
            let match = target.substring(with: range)
            let currLength = target.length
            for (title, linkTitle) in titlesWithoutLink {
                if match.contains(title) {
                    var uri = match.replacingOccurrences(of: title, with: "\(linkTitle)/")
                        .replacingOccurrences(of: "：", with: "/")
                        .replacingOccurrences(of: Constants.RegexPattern.bar, with: "", options: .regularExpression)
                        .replacingOccurrences(of: "；", with: prevLinkTitle)
                    var link = "<a href=\"\(uri)\">\(match)</a>"
                    if title == "；" {
                        uri = uri.replacingOccurrences(of: title, with: prevLinkTitle)
                        link = "；<a href=\"\(uri)\">\(match.replacingOccurrences(of: title, with: ""))</a>"
                    }
                    else {
                        prevLinkTitle = linkTitle
                    }
                    target = target.replacingOccurrences(of: match, with: link, range: range) as NSString
                    targetOffset += target.length - currLength
                    break
                }
            }
            for (title, linkTitle) in Constants.Dictionary.titlesWithLink {
                if match.contains(title) {
                    prevLinkTitle = linkTitle
                    break
                }
            }
        }
        return target as String
    }
    
    func getCSS() -> String {
        let font = UserDefaults.standard.bool(forKey: Constants.Config.font) ?
            Constants.Font.min : Constants.Font.kaku
        let fontSize = UserDefaults.standard.double(forKey: Constants.Config.size)
        let paddingSize = sqrt(sqrt(fontSize))
        let fontColor = UserDefaults.standard.bool(forKey: Constants.Config.night) ?
            "rgb(186,186,186)" : "rgb(0,0,0)"
        let backgroundColor = UserDefaults.standard.bool(forKey: Constants.Config.night) ?
            "rgb(33,34,37)" : "rgb(255,255,255)"
        let sideBySideEnabled = UserDefaults.standard.bool(forKey: Constants.Config.dual) &&
            UserDefaults.standard.bool(forKey: Constants.Config.side)
        
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
                \(sideBySideEnabled ? "padding: \(paddingSize / 2)em;" : "padding: \(paddingSize / 2)em \(paddingSize)em;")
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
                \(sideBySideEnabled ? "padding: \(paddingSize / 2)em;" : "padding: \(paddingSize / 2)em 0;")
                \(sideBySideEnabled ? "display: table-cell;" : "")
                \(sideBySideEnabled ? "width: 50%;" : "")
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
                background-size: \(paddingSize)em \(paddingSize / 2)em;
                display: inline-block;
                width: \(paddingSize)em;
                height: \(paddingSize / 2)em;
                position: absolute;
                left: 0;
                content: '';
            }
            """
        
        let paragraph =
            """
            .paragraph {
                \(sideBySideEnabled ? "padding: \(paddingSize / 2)em;" : "padding: \(paddingSize / 2)em 0;")
                \(sideBySideEnabled ? "display: table-cell;" : "")
                \(sideBySideEnabled ? "width: 50%;" : "")
            }
            """
        
        let hymnVerse =
            """
            .hymn-verse {
                \(sideBySideEnabled ? "padding: \(paddingSize / 2)em;" : "padding: \(paddingSize / 2)em 0;")
                \(sideBySideEnabled ? "display: table-cell;" : "")
                \(sideBySideEnabled ? "width: 50%;" : "")
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

