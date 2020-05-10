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
                print("Failed to remove old default Realm file")
                #endif
            }
        }
        
        do {
            try FileManager.default.moveItem(at: newRealmURL, to: defaultRealmFileURL)
        } catch {
            #if DEBUG
            print("Failed to rename new Realm file")
            #endif
        }
    }
    
    fileprivate func copyBundleRealmFile(to newRealmURL: URL) {
        if let bundleURL = Bundle.main.url(forResource: "JLQ", withExtension: "realm") {
            do {
                try FileManager.default.copyItem(at: bundleURL, to: newRealmURL)
            } catch {
                #if DEBUG
                print("Failed to copy Realm file from bundle")
                #endif
            }
        }
    }
    
    fileprivate func copyUserDataToNewRealmFile(from realmToCopy: Realm, to newRealmURL: URL) {
        let bookmarksToCopy = realmToCopy.objects(Bookmark.self).sorted(byKeyPath: "date")
        let highlightedTextsToCopy = realmToCopy.objects(HighlightedText.self).sorted(byKeyPath: "date")
        
        let newRealmConfig = Realm.Configuration(fileURL: newRealmURL, schemaVersion: currentSchemaVersion)
        let realm = try! Realm(configuration: newRealmConfig)
        try! realm.write {
            copyUserBookmarks(to: realm, bookmarks: bookmarksToCopy)
            copyUserHighlights(to: realm, highlightedTexts: highlightedTextsToCopy)
        }
    }
    
    fileprivate func copyUserBookmarks(to realm: Realm, bookmarks: Results<Bookmark>) {
        for bookmarkToCopy in bookmarks {
            let bookmark = Bookmark(id: bookmarkToCopy.id,
                                    namePrimary: bookmarkToCopy.name_primary,
                                    nameSecondary: bookmarkToCopy.name_secondary,
                                    scripture: realm.objects(Scripture.self).filter("id = '\(bookmarkToCopy.id)'").first!,
                                    date: bookmarkToCopy.date)
            realm.create(Bookmark.self, value: bookmark, update: .all)
        }
    }
    
    fileprivate func copyUserHighlights(to realm: Realm, highlightedTexts: Results<HighlightedText>) {
        for highlightedTextToCopy in highlightedTexts {
            let highlightedText = HighlightedText(id: highlightedTextToCopy.id,
                                                  namePrimary: highlightedTextToCopy.name_primary,
                                                  nameSecondary: highlightedTextToCopy.name_secondary,
                                                  text: highlightedTextToCopy.text,
                                                  note: highlightedTextToCopy.note,
                                                  highlightedScripture: highlightedTextToCopy.highlighted_scripture,
                                                  date: highlightedTextToCopy.date)
            realm.create(HighlightedText.self, value: highlightedText, update: .all)
        }
    }
}
