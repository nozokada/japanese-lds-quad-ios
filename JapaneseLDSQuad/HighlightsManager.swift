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
    
    func addHighlight(textId: String, textContent: String, scriptureId: String, scriptureContent: String, language: String) {
        if let existingHighlightedScripture = realm.objects(HighlightedScripture.self).filter("id = '\(scriptureId)'").first {
            try! realm.write {
                if language == Constants.LanguageCode.primary {
                    existingHighlightedScripture.scripture_primary = scriptureContent
                } else {
                    existingHighlightedScripture.scripture_secondary = scriptureContent
                }
            }
            addHighlightedText(id: textId, content: textContent, scripture: existingHighlightedScripture)
        }
        else {
            if let scripture = realm.objects(Scripture.self).filter("id = '\(scriptureId)'").first {
                let highlightedScriptureToAdd = HighlightedScripture()
                highlightedScriptureToAdd.id = scriptureId
                highlightedScriptureToAdd.scripture_primary = language == Constants.LanguageCode.primary
                    ? scriptureContent
                    : scripture.scripture_primary
                highlightedScriptureToAdd.scripture_secondary = language == Constants.LanguageCode.secondary
                    ? scriptureContent
                    : scripture.scripture_secondary
                highlightedScriptureToAdd.scripture = scripture
                highlightedScriptureToAdd.date = NSDate()
                
                try! realm.write {
                    realm.add(highlightedScriptureToAdd)
                }
                addHighlightedText(id: textId, content: textContent, scripture: highlightedScriptureToAdd)
            }
        }
        updateHighlightChange(id: scriptureId, content: scriptureContent, language: language)
    }
    
    private func addHighlightedText(id: String, content: String, scripture: HighlightedScripture) {
        let highlightedTextToAdd = HighlightedText()
        highlightedTextToAdd.id = id
        highlightedTextToAdd.name_primary = generateTitlePrimary(scripture: scripture.scripture)
        highlightedTextToAdd.name_secondary = generateTitleSecondary(scripture: scripture.scripture)
        highlightedTextToAdd.text = content
        highlightedTextToAdd.highlighted_scripture = scripture
        highlightedTextToAdd.date = NSDate()
        
        try! realm.write {
            realm.add(highlightedTextToAdd)
        }
    }
    
    func removeHighlight(id: String, content: String, contentLanguage: String) {
        if let highlightedTextToRemove = realm.objects(HighlightedText.self).filter("id = '\(id)'").first {
            let highlightedScripture = highlightedTextToRemove.highlighted_scripture!
            removeHighlightedText(highlightedTextToRemove: highlightedTextToRemove)
            updateHighlightChange(id: highlightedScripture.id, content: content, language: contentLanguage)
            
            if highlightedScripture.highlighted_texts.count == 0 {
                try! realm.write {
                    realm.delete(highlightedScripture)
                }
            }
        }
    }
    
    private func removeHighlightedText(highlightedTextToRemove: HighlightedText) {
        try! realm.write {
            realm.delete(highlightedTextToRemove)
        }
    }
    
    private func updateHighlightChange(id: String, content: String, language: String) {
        if let scripture = getScripture(id: id) {
            try! realm.write {
                if language == Constants.LanguageCode.primary {
                    scripture.scripture_primary = content
                } else {
                    scripture.scripture_secondary = content
                }
            }
        }
    }
    
}

