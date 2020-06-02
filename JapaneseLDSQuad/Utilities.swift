//
//  Utilities.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/3/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import Foundation
import RealmSwift
import AVFoundation

class Utilities {
    
    static let shared = Utilities()
    
    lazy var realm = try! Realm()
    
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
    
    var lastSyncedDate: Date {
        return UserDefaults.standard.object(forKey: Constants.Config.lastSynced) as! Date
    }
    
    var formattedLastSyncedDate: String {
        if lastSyncedDate == Date.distantPast {
            return "neverSynced".localized
        }
        return formatDate(date: lastSyncedDate)
    }
    
    func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("yMMMdE jm")
        return formatter.string(from: date)
    }
    
    func getFont(multiplySizeBy: Float = 1) -> UIFont? {
        let name = Utilities.shared.alternativeFontEnabled
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
    
    func getCSSFont() -> String {
        return alternativeFontEnabled ? Constants.Font.min : Constants.Font.kaku
    }
    
    func getCSSTextColor() -> String {
        return nightModeEnabled ? "rgb(186,186,186)" : "rgb(0,0,0)"
    }
    
    func getCSSBackgroundColor() -> String {
        return nightModeEnabled ? "rgb(33,34,37)" : "rgb(255,255,255)"
    }
    
    func isPaid(book: Book) -> Bool {
        return Constants.PaidContent.books.contains(book.link)
    }
    
    func isPaid(restorationIdentifider: String) -> Bool {
        return [Constants.RestorationID.highlights,
                Constants.RestorationID.account].contains(restorationIdentifider)
    }
    
    func getSystemLang() -> String? {
        return Locale.current.languageCode
    }
    
    func getBook(linkName: String) -> Book? {
        return realm.objects(Book.self).filter("link = '\(linkName)'").sorted(byKeyPath: "id").last
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
    
    func getScripture(id: String) -> Scripture? {
        return realm.object(ofType: Scripture.self, forPrimaryKey: id)
    }
    
    func getScriptures(chapterId: String) -> Results<Scripture> {
        return realm.objects(Scripture.self).filter("id BEGINSWITH '\(chapterId)'").sorted(byKeyPath: "id")
    }
    
    func getScriptures(query: String) -> Results<Scripture> {
        return realm.objects(Scripture.self).filter(query)
    }
    
    func generateTitlePrimary(scripture: Scripture) -> String {
        if scripture.parent_book.link.hasPrefix("gs") || scripture.parent_book.link.hasPrefix("jst") {
            if let title = Utilities.shared.getScripture(id: "\(scripture.id.prefix(4))title") {
                return "\(title.scripture_primary.tagsRemoved.verseAfterColonRemoved) : \(scripture.verse)"
            }
        }
        return "\(scripture.parent_book.name_primary) \(scripture.chapter) : \(scripture.verse)"
    }
    
    func generateTitleSecondary(scripture: Scripture) -> String {
        if scripture.parent_book.link.hasPrefix("gs") || scripture.parent_book.link.hasPrefix("jst") {
            if let title = Utilities.shared.getScripture(id: "\(scripture.id.prefix(4))title") {
                let titleSecondary = title.scripture_secondary.isEmpty ? title.scripture_primary : title.scripture_secondary
                return "\(titleSecondary.tagsRemoved.verseAfterColonRemoved) : \(scripture.verse)"
            }
        }
        return "\(scripture.parent_book.name_secondary) \(scripture.chapter) : \(scripture.verse)"
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

        if let viewController = storyboard?.instantiateViewController(
            withIdentifier: Constants.StoryBoardID.books) as? BooksViewController {
            viewController.initTargetBook(targetBook: grandParentBook)
            viewControllers.append(viewController)
        }

        if parentBook.child_scriptures.sorted(byKeyPath: "id").last?.chapter != 1 {
            if let viewController = storyboard?.instantiateViewController(
                withIdentifier: Constants.StoryBoardID.chapters) as? ChaptersViewController {
                viewController.initTargetBook(targetBook: parentBook)
                viewControllers.append(viewController)
            }
        }
        return viewControllers
    }
    
    func alert(view: UIView, title: String, message: String, handler: ((UIAlertAction) -> ())?) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        let action = UIAlertAction(title: NSLocalizedString("OK", comment: ""),
                                   style: .default, handler: handler)
        alertController.addAction(action)
        
        let popoverController = alertController.popoverPresentationController
        popoverController?.sourceView = view
        popoverController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY, width: 0, height: 0)
        popoverController?.permittedArrowDirections = []
        
        return alertController
    }
}
