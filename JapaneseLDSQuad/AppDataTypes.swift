//
//  AppDataTypes.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 3/5/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import Foundation

struct TargetScriptureData {
    
    var book: Book
    var chapter: Int
    var verse: String?
    
    init(book: Book, chapter: Int, verse: String? = nil) {
        self.book = book
        self.chapter = chapter
        self.verse = verse
    }
}

struct ContentViewData {
    
    var index: Int
    var builder: ContentBuilder
    var chapterId: String
    var verse: String?
    
    init(index: Int, builder: ContentBuilder, chapterId: String, verse: String?) {
        self.index = index
        self.builder = builder
        self.chapterId = chapterId
        self.verse = verse
    }
}
