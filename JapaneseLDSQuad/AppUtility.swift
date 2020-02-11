//
//  AppUtility.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/3/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import Foundation
import RealmSwift

class AppUtility {
    
    static let shared = AppUtility()
    
    func getContentType(targetBook: Book) -> String {
        var contentType: String
        if targetBook.link.hasSuffix("_cont") {
            contentType = Constants.ContentType.aux
        } else if targetBook.link.hasPrefix("gs") {
            contentType = Constants.ContentType.gs
        } else if targetBook.link.hasPrefix("hymns") {
            contentType = Constants.ContentType.hymn
        } else {
            contentType = Constants.ContentType.main
        }
        return contentType
    }
    
    func getContentBuilder(scriptures: Results<Scripture>, contentType: String) -> ContentBuilder {
        switch contentType {
        case Constants.ContentType.aux:
            return ContentBuilder(scriptures: scriptures)
        case Constants.ContentType.gs:
            return BibleDictionaryBuilder(scriptures: scriptures)
        case Constants.ContentType.hymn:
            return HymnBuilder(scriptures: scriptures)
        default:
            return ContentBuilder(scriptures: scriptures, numbered: true)
        }
    }
    
    func getChapterId(bookId: String, chapter: Int) -> String {
        return "\(bookId)\(String(chapter / 10, radix: 21).uppercased())\(String(chapter % 10))"
    }
    
    func getChapterNumber(id: String) -> Int {
        let chapter = id.prefix(4).suffix(2)
        return Int(String(chapter.first!), radix: 21)! * 10 + Int(String(chapter.last!))!
    }
}
