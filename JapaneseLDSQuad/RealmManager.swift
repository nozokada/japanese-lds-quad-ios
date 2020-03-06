//
//  RealmManager.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 3/6/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import Foundation
import RealmSwift

class RealmManager {
    
    static let shared = RealmManager()
    
    let defaultRealmFileURL = Realm.Configuration.defaultConfiguration.fileURL!
    let currentSchemaVersion = Constants.Version.realmSchema
    
    func setUpRealm() {
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
    
    func getRealmMigrationConfig(realmFileURL: URL) -> Realm.Configuration {
        return Realm.Configuration(
            fileURL: realmFileURL,
            schemaVersion: currentSchemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
                if (oldSchemaVersion < self.currentSchemaVersion) {
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
    
    func createNewRealmFile(existingRealm: Realm?) {
        let defaultRealmDirectoryURL = defaultRealmFileURL.deletingLastPathComponent()
        let newRealmURL = defaultRealmDirectoryURL.appendingPathComponent(Constants.File.initialRealm)
        copyBundleRealmFile(to: newRealmURL)
        if let realm = existingRealm {
            copyUserDataToNewRealmFile(from: realm, to: newRealmURL)
            do {
                try FileManager.default.removeItem(at: defaultRealmFileURL)
            } catch {
                debugPrint("Failed to remove old default Realm file")
            }
        }
        
        do {
            try FileManager.default.moveItem(at: newRealmURL, to: defaultRealmFileURL)
        } catch {
            debugPrint("Failed to rename new Realm file")
        }
    }
    
    func copyBundleRealmFile(to newRealmURL: URL) {
        if let bundleURL = Bundle.main.url(forResource: "JLQ", withExtension: "realm") {
            do {
                try FileManager.default.copyItem(at: bundleURL, to: newRealmURL)
            } catch {
                debugPrint("Failed to copy Realm file from bundle")
            }
        }
    }
    
    func copyUserDataToNewRealmFile(from realmToCopy: Realm, to newRealmURL: URL) {
        let bookmarksToCopy = realmToCopy.objects(Bookmark.self).sorted(byKeyPath: "date")
        let highlightedScripturesToCopy = realmToCopy.objects(HighlightedScripture.self).sorted(byKeyPath: "date")
        let highlightedTextsToCopy = realmToCopy.objects(HighlightedText.self).sorted(byKeyPath: "date")
        
        let newRealmConfig = Realm.Configuration(fileURL: newRealmURL, schemaVersion: currentSchemaVersion)
        let realm = try! Realm(configuration: newRealmConfig)
        try! realm.write {
            copyUserBookmarks(to: realm, bookmarks: bookmarksToCopy)
            copyUserHighlightedScriptures(to: realm, highlightedScriptures: highlightedScripturesToCopy)
            copyUserHighlightedText(to: realm, highlightedTexts: highlightedTextsToCopy)
        }
    }
    
    func copyUserBookmarks(to realm: Realm, bookmarks: Results<Bookmark>) {
        for bookmarkToCopy in bookmarks {
            let bookmark = Bookmark(id: bookmarkToCopy.id,
                                    namePrimary: bookmarkToCopy.name_primary,
                                    nameSecondary: bookmarkToCopy.name_secondary,
                                    scripture: realm.objects(Scripture.self).filter("id = '\(bookmarkToCopy.id)'").first!,
                                    date: bookmarkToCopy.date)
            realm.create(Bookmark.self, value: bookmark, update: .all)
        }
    }
    
    func copyUserHighlightedScriptures(to realm: Realm, highlightedScriptures: Results<HighlightedScripture>) {
        for highlightedScriptureToCopy in highlightedScriptures {
            if let scripture = realm.objects(Scripture.self).filter("id = '\(highlightedScriptureToCopy.id)'").first {
                scripture.scripture_primary = highlightedScriptureToCopy.scripture_primary
                scripture.scripture_secondary = highlightedScriptureToCopy.scripture_secondary
                let highlightedScripture = HighlightedScripture(id: highlightedScriptureToCopy.id,
                                                                scripturePrimary: highlightedScriptureToCopy.scripture_primary,
                                                                scriptureSecondary: highlightedScriptureToCopy.scripture_secondary,
                                                                scripture: scripture,
                                                                date: highlightedScriptureToCopy.date)
                realm.create(HighlightedScripture.self, value: highlightedScripture, update: .all)
            }
        }
    }
    
    func copyUserHighlightedText(to realm: Realm, highlightedTexts: Results<HighlightedText>) {
        for highlightedTextToCopy in highlightedTexts {
            let highlightedText = HighlightedText(id: highlightedTextToCopy.id,
                                                  namePrimary: highlightedTextToCopy.name_primary,
                                                  nameSecondary: highlightedTextToCopy.name_secondary,
                                                  text: highlightedTextToCopy.text,
                                                  note:  highlightedTextToCopy.note,
                                                  highlightedScripture: highlightedTextToCopy.highlighted_scripture,
                                                  date: highlightedTextToCopy.date)
            realm.create(HighlightedText.self, value: highlightedText, update: .all)
        }
    }
}
