//
//  SetupManager.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 3/6/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import Foundation
import RealmSwift

class SetupManager {
    
    static let shared = SetupManager()
    
    let defaultRealmFileURL = Realm.Configuration.defaultConfiguration.fileURL!
    let currentSchemaVersion = Constants.Version.realmSchema
    
    func initUserDefaults() {
        UserDefaults.standard.register(defaults: [Constants.Config.font: false])
        UserDefaults.standard.register(defaults: [Constants.Config.night: false])
        UserDefaults.standard.register(defaults: [Constants.Config.dual: false])
        UserDefaults.standard.register(defaults: [Constants.Config.side: false])
        UserDefaults.standard.register(defaults: [Constants.Config.size: 1.0])
        UserDefaults.standard.register(defaults: [Constants.Config.rate: 1.0])
        UserDefaults.standard.register(defaults: [Constants.Config.pass: false])
        UserDefaults.standard.register(defaults: [Constants.Config.sync: false])
        UserDefaults.standard.register(defaults: [Constants.Config.lastSynced: Date.distantPast])
    }
    
    func initRealm() {
        if FileManager.default.fileExists(atPath: defaultRealmFileURL.path) {
            let migrationConfig = getRealmMigrationConfig(realmFileURL: defaultRealmFileURL)
            let realm = try! Realm(configuration: migrationConfig)
            createNewRealmFile(existingRealm: realm)
        } else {
            createNewRealmFile(existingRealm: nil)
        }
        Realm.Configuration.defaultConfiguration.schemaVersion = currentSchemaVersion
        _ = try! Realm()
    }
    
    fileprivate func getRealmMigrationConfig(realmFileURL: URL) -> Realm.Configuration {
        return Realm.Configuration(
            fileURL: realmFileURL,
            schemaVersion: currentSchemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
                if (oldSchemaVersion < 2) {
                    migration.renameProperty(onType: Book.className(), from: "name_jpn", to: "name_primary")
                    migration.renameProperty(onType: Book.className(), from: "name_eng", to: "name_secondary")
                    migration.renameProperty(onType: Scripture.className(), from: "scripture_jpn", to: "scripture_primary")
                    migration.renameProperty(onType: Scripture.className(), from: "scripture_eng", to: "scripture_secondary")
                    migration.renameProperty(onType: Scripture.className(), from: "scripture_jpn_search", to: "scripture_primary_raw")
                    migration.renameProperty(onType: Scripture.className(), from: "scripture_eng_search", to: "scripture_secondary_raw")
                    migration.renameProperty(onType: HighlightedScripture.className(), from: "scripture_jpn", to: "scripture_primary")
                    migration.renameProperty(onType: HighlightedScripture.className(), from: "scripture_eng", to: "scripture_secondary")
                    migration.renameProperty(onType: HighlightedText.className(), from: "name_jpn", to: "name_primary")
                    migration.renameProperty(onType: HighlightedText.className(), from: "name_eng", to: "name_secondary")
                    migration.renameProperty(onType: Bookmark.className(), from: "name_jpn", to: "name_primary")
                    migration.renameProperty(onType: Bookmark.className(), from: "name_eng", to: "name_secondary")
                }
        })
    }
    
    fileprivate func createNewRealmFile(existingRealm: Realm?) {
        let defaultRealmDirectoryURL = defaultRealmFileURL.deletingLastPathComponent()
        let newRealmURL = defaultRealmDirectoryURL.appendingPathComponent(Constants.File.initialRealm)
        copyBundleRealmFile(to: newRealmURL)
        if let realm = existingRealm {
            copyUserDataToNewRealmFile(from: realm, to: newRealmURL)
            do {
                try FileManager.default.removeItem(at: defaultRealmFileURL)
            } catch {
                #if DEBUG
                print("Removing old default Realm file failed")
                #endif
            }
        }
        
        do {
            try FileManager.default.moveItem(at: newRealmURL, to: defaultRealmFileURL)
        } catch {
            #if DEBUG
            print("Renaming new Realm file failed")
            #endif
        }
    }
    
    fileprivate func copyBundleRealmFile(to newRealmURL: URL) {
        if let bundleURL = Bundle.main.url(forResource: "JLQ", withExtension: "realm") {
            do {
                try FileManager.default.copyItem(at: bundleURL, to: newRealmURL)
            } catch {
                #if DEBUG
                print("Copying Realm file from bundle failed")
                #endif
            }
        }
    }
    
    fileprivate func copyUserDataToNewRealmFile(from realmToCopy: Realm, to newRealmURL: URL) {
        let bookmarksToCopy = realmToCopy.objects(Bookmark.self).sorted(byKeyPath: "date")
        let highlightsToCopy = realmToCopy.objects(HighlightedText.self).sorted(byKeyPath: "date")
        
        let newRealmConfig = Realm.Configuration(fileURL: newRealmURL, schemaVersion: currentSchemaVersion)
        let realm = try! Realm(configuration: newRealmConfig)
        try! realm.write {
            copyUserBookmarks(to: realm, bookmarks: bookmarksToCopy)
            copyUserHighlights(to: realm, highlights: highlightsToCopy)
            enableGSBibleLinks(to: realm)
        }
    }
    
    fileprivate func copyUserBookmarks(to realm: Realm, bookmarks: Results<Bookmark>) {
        bookmarks.forEach { bookmarkToCopy in
            let bookmark = Bookmark(
                id: bookmarkToCopy.id,
                namePrimary: bookmarkToCopy.name_primary,
                nameSecondary: bookmarkToCopy.name_secondary,
                scripture: realm.object(ofType: Scripture.self, forPrimaryKey: bookmarkToCopy.id)!,
                date: bookmarkToCopy.date)
            realm.create(Bookmark.self, value: bookmark, update: .all)
        }
    }
    
    fileprivate func copyUserHighlights(to realm: Realm, highlights: Results<HighlightedText>) {
        highlights.forEach { highlightsToCopy in 
            let highlight = HighlightedText(
                id: highlightsToCopy.id,
                namePrimary: highlightsToCopy.name_primary,
                nameSecondary: highlightsToCopy.name_secondary,
                text: highlightsToCopy.text,
                note: highlightsToCopy.note,
                userScripture: highlightsToCopy.highlighted_scripture,
                date: highlightsToCopy.date)
            realm.create(HighlightedText.self, value: highlight, update: .all)
        }
    }
    
    fileprivate func enableGSBibleLinks(to realm: Realm) {
        if !PurchaseManager.shared.allFeaturesUnlocked {
            return
        }
        let gsBooks = realm.objects(Book.self).filter("link BEGINSWITH 'gs_'")
        gsBooks.forEach { gsBook in
            gsBook.child_scriptures.forEach { scripture in
                scripture.scripture_primary = addBibleLinks(gsString: scripture.scripture_primary)
            }
        }
    }
    
    fileprivate func addBibleLinks(gsString: String) -> String {
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
                    } else {
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
