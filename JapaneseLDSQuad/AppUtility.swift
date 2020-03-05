//
//  AppUtility.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/3/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import Foundation
import RealmSwift
import AVFoundation

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

class AppUtility {
    
    static let shared = AppUtility()
    
    var alternativeFontEnabled: Bool {
        return UserDefaults.standard.bool(forKey: Constants.Config.font)
    }
    
    var nightModeEnabled: Bool {
        return UserDefaults.standard.bool(forKey: Constants.Config.night)
    }
    
    var dualEnabled: Bool {
         return UserDefaults.standard.bool(forKey: Constants.Config.dual)
    }
    
    var sideBySideEnabled: Bool {
        return UserDefaults.standard.bool(forKey: Constants.Config.side)
    }
    
    var fontSizeMultiplier: Double {
        return UserDefaults.standard.double(forKey: Constants.Config.size)
    }
    
    var speechRateMultiplier: Float {
        return UserDefaults.standard.float(forKey: Constants.Config.rate)
    }
    
    func getFont(multiplySizeBy: Float = 1) -> UIFont? {
        let name = AppUtility.shared.alternativeFontEnabled
            ? Constants.Font.min
            : Constants.Font.kaku
        let size = Constants.TextSize.standard * Float(fontSizeMultiplier) * multiplySizeBy
        return UIFont(name: name, size: CGFloat(size))
    }
    
    func getSpeechRate() -> Float {
        return AVSpeechUtteranceDefaultSpeechRate * speechRateMultiplier
    }
    
    func getTextColor() -> UIColor {
        return nightModeEnabled ? Constants.TextColor.night : Constants.TextColor.day
    }
    
    func getCellColor() -> UIColor {
        return nightModeEnabled ? Constants.CellColor.night : Constants.CellColor.day
    }
    
    func getBackgroundColor() -> UIColor {
        return nightModeEnabled ? Constants.BackgroundColor.night : Constants.BackgroundColor.day
    }
    
    func isPaid(book: Book) -> Bool {
        return Constants.PaidContent.books.contains(book.link)
    }
    
    func isPaid(restorationIdentifider: String) -> Bool {
        return [Constants.RestorationID.highlights].contains(restorationIdentifider)
    }
    
    func getChapterIdFromChapterNumber(bookId: String, chapter: Int) -> String {
        return "\(bookId)\(String(chapter / 10, radix: 21).uppercased())\(String(chapter % 10))"
    }
    
    func getChapterIdFromScripture(scripture: Scripture) -> String {
        return String(scripture.id.prefix(4))
    }
    
    func getChapterNumberFromScriptureId(id: String) -> Int {
        let chapter = id.prefix(4).suffix(2)
        return Int(String(chapter.first!), radix: 21)! * 10 + Int(String(chapter.last!))!
    }
    
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
    
    func getParentViewControllers(storyboard: UIStoryboard?, scripture: Scripture) -> [UIViewController] {
        let parentBook = scripture.parent_book!
        let grandParentBook = parentBook.parent_book!
        var viewControllers = [UIViewController]()

        if let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.books) as? BooksViewController {
            viewController.initTargetBook(targetBook: grandParentBook)
            viewControllers.append(viewController)
        }

        if parentBook.child_scriptures.sorted(byKeyPath: "id").last?.chapter != 1 {
            if let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.chapters) as? ChaptersViewController {
                viewController.initTargetBook(targetBook: parentBook)
                viewControllers.append(viewController)
            }
        }
        return viewControllers
    }
    
    func alert(_ title: String, message: String) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        let action = UIAlertAction(title: NSLocalizedString("OK", comment: ""),
                                   style: .default, handler: nil)
        alertController.addAction(action)
        return alertController
    }
}
