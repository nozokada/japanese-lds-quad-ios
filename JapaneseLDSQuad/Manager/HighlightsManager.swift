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
        
        createHighlight(id: textId, content: textContent, scripture: highlightedScripture)
        applyHighlightChanges(id: scriptureId, content: scriptureContent, language: language)
    }
    
    func remove(id: String, content: String, language: String) {
        if let highlightedText = realm.objects(HighlightedText.self).filter("id = '\(id)'").first {
            let highlightedScripture = highlightedText.highlighted_scripture!
            deleteHighlight(highlightedTextToRemove: highlightedText)
            applyHighlightChanges(id: highlightedScripture.id, content: content, language: language)
            if highlightedScripture.highlighted_texts.count == 0 {
                try! realm.write {
                    realm.delete(highlightedScripture)
                    #if DEBUG
                    print("Removed highlighted scripture successfully")
                    #endif
                }
            }
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
            print("Added highlighted scripture \(scripture.id) successfully")
            #endif
        }
        return highlightedScripture
    }
    
    fileprivate func createHighlight(id: String, content: String, scripture: HighlightedScripture) {
        let highlightedText = HighlightedText(id: id,
                                              namePrimary: Utilities.shared.generateTitlePrimary(scripture: scripture.scripture),
                                              nameSecondary: Utilities.shared.generateTitleSecondary(scripture: scripture.scripture),
                                              text: content,
                                              note: "",
                                              highlightedScripture: scripture,
                                              date: NSDate())
        try! realm.write {
            realm.add(highlightedText)
            #if DEBUG
            print("Added highlighted text for scripture \(scripture.id) successfully")
            #endif
        }
    }
    
    fileprivate func applyHighlightChanges(id: String, content: String, language: String) {
        if let scripture = Utilities.shared.getScripture(id: id) {
            try! realm.write {
                if language == Constants.Language.primary {
                    scripture.scripture_primary = content
                } else {
                    scripture.scripture_secondary = content
                }
            }
        }
    }
    
    fileprivate func deleteHighlight(highlightedTextToRemove: HighlightedText) {
        try! realm.write {
            realm.delete(highlightedTextToRemove)
            #if DEBUG
            print("Removed highlighted text for scripture successfully")
            #endif
        }
    }
}
