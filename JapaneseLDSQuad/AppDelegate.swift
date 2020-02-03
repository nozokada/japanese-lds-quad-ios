//
//  AppDelegate.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/2/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    let defaultRealmFileURL = Realm.Configuration.defaultConfiguration.fileURL!
    let currentSchemaVersion: UInt64 = 2

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        configureUserDefaults()
        setUpRealm()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func configureUserDefaults() {
        UIApplication.shared.isIdleTimerDisabled = true
        UserDefaults.standard.register(defaults: [Constants.Config.font: false])
        UserDefaults.standard.register(defaults: [Constants.Config.night: false])
        UserDefaults.standard.register(defaults: [Constants.Config.dual: false])
        UserDefaults.standard.register(defaults: [Constants.Config.side: false])
        UserDefaults.standard.register(defaults: [Constants.Config.size: 1.0])
        UserDefaults.standard.register(defaults: [Constants.Config.pass: false])
    }
    
    func setUpRealm() {
        if FileManager.default.fileExists(atPath: defaultRealmFileURL.path) {
            let realmMigrationConfig = getRealmConfiguration(realmFileURL: defaultRealmFileURL)
            let existingRealm = try! Realm(configuration: realmMigrationConfig)
            createNewRealmFile(from: existingRealm)
        } else {
            createNewRealmFile(from: nil)
        }
        Realm.Configuration.defaultConfiguration.schemaVersion = currentSchemaVersion
        _ = try! Realm()
    }
    
    func getRealmConfiguration(realmFileURL: URL) -> Realm.Configuration {
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
    
    func createNewRealmFile(from realmToCopy: Realm?) {
        let defaultRealmDirectoryURL = defaultRealmFileURL.deletingLastPathComponent()
        let newRealmURL = defaultRealmDirectoryURL.appendingPathComponent(Constants.File.initialRealm)
        copyBundledRealmFile(to: newRealmURL)
        if let realm = realmToCopy {
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
    
    func copyBundledRealmFile(to newRealmURL: URL) {
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
            let bookmark = Bookmark()
            bookmark.id = bookmarkToCopy.id
            bookmark.name_primary = bookmarkToCopy.name_primary
            bookmark.name_secondary = bookmarkToCopy.name_secondary
            bookmark.scripture = realm.objects(Scripture.self).filter("id = '\(bookmarkToCopy.id)'").first
            bookmark.date = bookmarkToCopy.date
            
            realm.create(Bookmark.self, value: bookmark, update: .all)
        }
    }
    
    func copyUserHighlightedScriptures(to realm: Realm, highlightedScriptures: Results<HighlightedScripture>) {
        for highlightedScriptureToCopy in highlightedScriptures {
            if let scripture = realm.objects(Scripture.self).filter("id = '\(highlightedScriptureToCopy.id)'").first {
                scripture.scripture_primary = highlightedScriptureToCopy.scripture_primary
                scripture.scripture_secondary = highlightedScriptureToCopy.scripture_secondary
                
                let highlightedScripture = HighlightedScripture()
                highlightedScripture.id = highlightedScriptureToCopy.id
                highlightedScripture.scripture_primary = highlightedScriptureToCopy.scripture_primary
                highlightedScripture.scripture_secondary = highlightedScriptureToCopy.scripture_secondary
                highlightedScripture.scripture = scripture
                highlightedScripture.date = highlightedScriptureToCopy.date
                
                realm.create(HighlightedScripture.self, value: highlightedScripture, update: .all)
            }
        }
    }
    
    func copyUserHighlightedText(to realm: Realm, highlightedTexts: Results<HighlightedText>) {
        for highlightedTextToCopy in highlightedTexts {
            let highlightedText = HighlightedText()
            highlightedText.id = highlightedTextToCopy.id
            highlightedText.name_primary = highlightedTextToCopy.name_primary
            highlightedText.name_secondary = highlightedTextToCopy.name_secondary
            highlightedText.text = highlightedTextToCopy.text
            highlightedText.note = highlightedTextToCopy.note
            highlightedText.highlighted_scripture = highlightedTextToCopy.highlighted_scripture
            highlightedText.date = highlightedTextToCopy.date
            
            realm.create(HighlightedText.self, value: highlightedText, update: .all)
        }
    }
}
