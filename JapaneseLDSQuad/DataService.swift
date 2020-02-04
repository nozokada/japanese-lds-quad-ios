//
//  DataService.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/3/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import Foundation

class DataService {
    static let shared = DataService()
    
    func getChapterId(bookId: String, chapter: Int) -> String {
        return "\(bookId)\(String(chapter / 10, radix: 21).uppercased())\(String(chapter % 10))"
    }
    
    func getChapterNumber(id: String) -> Int {
        let chapter = id.prefix(4).suffix(2)
        return Int(String(chapter.first!), radix: 21)! * 10 + Int(String(chapter.last!))!
    }
}
