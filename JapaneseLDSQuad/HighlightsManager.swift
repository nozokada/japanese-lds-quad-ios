//
//  HighlightManager.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/4/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit
import RealmSwift

class HighlightsManager: AnnotationsManager {
    
    static let shared = HighlightsManager()
    
    private func ApplyHighlightChangeToScripture(id: String, content: String, language: String) {
        if let scripture = getScripture(id: id) {
            try! realm.write {
                if language == Constants.Language.primary {
                    scripture.scripture_primary = content
                } else {
                    scripture.scripture_secondary = content
                }
            }
        }
    }
    
    func addHighlight(textId: String, textContent: String, scriptureId: String, scriptureContent: String, language: String) {
        if let existingHighlightedScripture = realm.objects(HighlightedScripture.self).filter("id = '\(scriptureId)'").first {
            addHighlightedText(id: textId, content: textContent, scripture: existingHighlightedScripture)
        } else {
            if let scripture = realm.objects(Scripture.self).filter("id = '\(scriptureId)'").first {
                let highlightedScripture = HighlightedScripture(id: scriptureId,
                                                                scripturePrimary: language == Constants.Language.primary
                                                                    ? scriptureContent
                                                                    : scripture.scripture_primary,
                                                                scriptureSecondary: language == Constants.Language.secondary
                                                                    ? scriptureContent
                                                                    : scripture.scripture_secondary,
                                                                scripture: scripture,
                                                                date: NSDate())
                try! realm.write {
                    realm.add(highlightedScripture)
                    #if Debug
                    debugPrint("Added highlighted scripture \(scripture.id) successfully")
                    #endif
                }
                addHighlightedText(id: textId, content: textContent, scripture: highlightedScripture)
            }
        }
        ApplyHighlightChangeToScripture(id: scriptureId, content: scriptureContent, language: language)
    }
    
    private func addHighlightedText(id: String, content: String, scripture: HighlightedScripture) {
        let highlightedText = HighlightedText(id: id,
                                              namePrimary: generateTitlePrimary(scripture: scripture.scripture),
                                              nameSecondary: generateTitleSecondary(scripture: scripture.scripture),
                                              text: content,
                                              note: "",
                                              highlightedScripture: scripture,
                                              date: NSDate())
        try! realm.write {
            realm.add(highlightedText)
            #if Debug
            debugPrint("Added highlighted text for scripture \(scripture.id) successfully")
            #endif
        }
    }
    
    func removeHighlight(id: String, content: String, language: String) {
        if let highlightedText = realm.objects(HighlightedText.self).filter("id = '\(id)'").first {
            let highlightedScripture = highlightedText.highlighted_scripture!
            removeHighlightedText(highlightedTextToRemove: highlightedText)
            ApplyHighlightChangeToScripture(id: highlightedScripture.id, content: content, language: language)
            if highlightedScripture.highlighted_texts.count == 0 {
                try! realm.write {
                    realm.delete(highlightedScripture)
                    #if Debug
                    debugPrint("Removed highlighted scripture successfully")
                    #endif
                }
            }
        }
    }
    
    private func removeHighlightedText(highlightedTextToRemove: HighlightedText) {
        try! realm.write {
            realm.delete(highlightedTextToRemove)
            #if Debug
            debugPrint("Removed highlighted text for scripture successfully")
            #endif
        }
    }
}
