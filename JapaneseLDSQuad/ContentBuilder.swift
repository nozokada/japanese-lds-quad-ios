//
//  ContentBuilder.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/6/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import Foundation
import RealmSwift

protocol ContentBuilder {
    var realm: Realm { get set }
    var dualEnabled: Bool { get }
    var scriptures: Results<Scripture> { get set }
    var targetVerse: String { get set }
    
    func buildTitle() -> String
    func buildPrefaces() -> String
    func buildBody() -> String
}

extension ContentBuilder {
    var dualEnabled: Bool {
        return UserDefaults.standard.bool(forKey: Constants.Config.dual)
    }

    func buildPrefaces() -> String {
        var html = ""
        if let preface = scriptures.filter("verse = 'preface'").first {
            if dualEnabled { html += "<hr>" }
            html += "<div class='paragraph'>\(preface.scripture_primary)</div>"
            html += dualEnabled ? "<div class='paragraph'>\(preface.scripture_secondary)</div>" : ""
        }
        
        if let intro = scriptures.filter("verse = 'intro'").first {
            html += dualEnabled ? "<hr>" : ""
            html += "<div class='paragraph'>\(intro.scripture_primary)</div>"
            html += dualEnabled ? "<div class='paragraph'>\(intro.scripture_secondary)</div>" : ""
        }
        
        if let summary = scriptures.filter("verse = 'summary'").first {
            html += dualEnabled ? "<hr>" : ""
            html += summary.scripture_primary.isEmpty ? "" : "<div class='paragraph'><i>\(summary.scripture_primary)</i></div>"
            html += dualEnabled ? "<div class='paragraph'><i>\(summary.scripture_secondary)</i></div>" : ""
        }
        return html
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
