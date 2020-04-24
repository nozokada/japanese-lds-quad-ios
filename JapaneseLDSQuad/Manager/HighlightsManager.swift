//
//  HighlightManager.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/4/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit
import RealmSwift

class HighlightsManager {
    
    static let shared = HighlightsManager()
    
    lazy var realm = try! Realm()
    
    func get(scriptureId: String) -> HighlightedScripture? {
        return realm.object(ofType: HighlightedScripture.self, forPrimaryKey: scriptureId)
    }
    
    func getAll(sortBy: String = "date", ascending: Bool = false) -> Results<HighlightedScripture> {
        return realm.objects(HighlightedScripture.self).sorted(byKeyPath: sortBy, ascending: ascending)
    }
    
    func add(textId: String, textContent: String, scriptureId: String, scriptureContent: String, language: String) {
        guard let scripture = Utilities.shared.getScripture(id: scriptureId) else {
            return
        }
        let highlightedScripture = get(scriptureId: scriptureId) ?? create(scripture: scripture)
        createHighlight(id: textId, content: textContent, scripture: highlightedScripture, sync: true)
        applyHighlightChanges(highlightedScripture: highlightedScripture, content: scriptureContent, language: language)
    }
    
    func remove(id: String, content: String, language: String) {
        guard let highlight = realm.object(ofType: HighlightedText.self, forPrimaryKey: id),
            let highlightedScripture = highlight.highlighted_scripture else {
            return
        }
        deleteHighlight(highlight: highlight, sync: true)
        applyHighlightChanges(highlightedScripture: highlightedScripture, content: content, language: language)
        if highlightedScripture.highlighted_texts.count == 0 {
            try! realm.write {
                realm.delete(highlightedScripture)
            }
            #if DEBUG
            print("Highlighted scripture was removed successfully")
            #endif
        }
    }
    
    fileprivate func create(scripture: Scripture, sync: Bool = false) -> HighlightedScripture {
        let highlightedScripture = HighlightedScripture(
            id: scripture.id,
            scripture: scripture,
            date: NSDate()
        )
        try! realm.write {
            realm.add(highlightedScripture)
            #if DEBUG
            print("Highlighted scripture \(scripture.id) was added successfully")
            #endif
        }
        return highlightedScripture
    }
    
    fileprivate func createHighlight(id: String, content: String, scripture: HighlightedScripture, sync: Bool = false) {
        let highlight = HighlightedText(
            id: id,
            namePrimary: Utilities.shared.generateTitlePrimary(scripture: scripture.scripture),
            nameSecondary: Utilities.shared.generateTitleSecondary(scripture: scripture.scripture),
            text: content,
            note: "",
            highlightedScripture: scripture,
            date: NSDate()
        )
        try! realm.write {
            realm.add(highlight)
        }
        #if DEBUG
        print("Highlight for \(highlight.name_primary) was added successfully")
        #endif
        if sync {
            FirestoreManager.shared.addHighlight(highlight)
        }
    }
    
    fileprivate func deleteHighlight(highlight: HighlightedText, sync: Bool = false) {
        let id = highlight.id
        try! realm.write {
            realm.delete(highlight)
        }
        #if DEBUG
        print("Highlight \(id) was deleted successfully")
        #endif
        if sync {
            FirestoreManager.shared.removeHighlight(id: id)
        }
    }
    
    fileprivate func applyHighlightChanges(highlightedScripture: HighlightedScripture, content: String, language: String) {
        try! realm.write {
            if language == Constants.Language.primary {
                highlightedScripture.scripture.scripture_primary = content
            } else {
                highlightedScripture.scripture.scripture_secondary = content
            }
        }
    }
}
