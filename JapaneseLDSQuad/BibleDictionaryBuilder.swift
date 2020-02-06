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
        }
        return html
    }

    func buildBody() -> String {
        var html = ""
        let verse = ""
        for scripture in scriptures {
            if scripture.id.count == 6 {
                if scripture.verse == targetVerse {
                    html += "<a id='anchor'></a>"
                }
                let bookmarked = realm.objects(Bookmark.self).filter("id = '\(scripture.id)'").first != nil ? true : false
                html += "<div id='\(scripture.id)'"
                html += bookmarked ? " class='bookmarked'>" : ">"
                let primaryScripture = PurchaseManager.shared.isPurchased ? getGSWithBibleLinks(gsString: scripture.scripture_primary) : scripture.scripture_primary
                html += "<div class='verse'><a class='verse-number' href='\(scripture.id)/bookmark'>\(verse)</a> <span lang='\(Constants.LanguageCode.primary)'>\(primaryScripture)</span></div>"
                html += "</div>"
            }
        }
        return html
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
}
