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
    
    var delegate: ContentChangeDelegate?
    lazy var realm = try! Realm()
    
    func get(scriptureId: String) -> HighlightedScripture? {
        return realm.object(ofType: HighlightedScripture.self, forPrimaryKey: scriptureId)
    }
    
    func get(textId: String) -> HighlightedText? {
        return realm.object(ofType: HighlightedText.self, forPrimaryKey: textId)
    }
    
    func getAll() -> Results<HighlightedScripture> {
        return realm.objects(HighlightedScripture.self)
    }
    
    func getAll(sortBy: String,
                ascending: Bool = false,
                searchQuery: String? = nil) -> Results<HighlightedText> {
        if let query = searchQuery {
            return realm.objects(HighlightedText.self)
                .filter(query)
                .sorted(byKeyPath: sortBy, ascending: ascending)
        }
        return realm.objects(HighlightedText.self)
            .sorted(byKeyPath: sortBy, ascending: ascending)
    }
    
    func add(id: String,
             text: String,
             highlightedScripture: HighlightedScripture,
             content: String,
             lang: String) {
        updateScriptureContent(highlightedScripture, content: content, lang: lang)
        let highlight = createHighlight(
            id: id,
            text: text,
            scripture: highlightedScripture,
            date: highlightedScripture.date as Date)
        write(highlight)
        FirestoreManager.shared.addHighlight(highlight) {
            FirestoreManager.shared.addToUserScripture(highlight)
        }
    }
    
    func remove(textId: String, content: String, lang: String) {
        guard let highlight = get(textId: textId) else {
            return
        }
        guard let highlightedScripture = createHighlightedScripture(
            id: highlight.highlighted_scripture.id,
            date: Date()) else {
            return
        }
        updateScriptureContent(highlightedScripture, content: content, lang: lang)
        let id = highlight.id
        delete(highlight)
        FirestoreManager.shared.removeFromUserScripture(id: id, scripture: highlightedScripture) {
            FirestoreManager.shared.removeHighlight(id: id)
            if highlightedScripture.highlighted_texts.count == 0 {
                let id = highlightedScripture.id
                self.delete(highlightedScripture)
                FirestoreManager.shared.removeUserScripture(id: id)
            }
        }
    }
    
    func update(textId: String, note: String) {
        guard let highlight = get(textId: textId) else {
            return
        }
        let updatedAt = NSDate()
        try! realm.write {
            highlight.note = note
            highlight.date = updatedAt
            highlight.highlighted_scripture.date = updatedAt
        }
        FirestoreManager.shared.addHighlight(highlight) {
            FirestoreManager.shared.addToUserScripture(highlight)
        }
    }
    
    func sync(highlights: [HighlightedText], scripture: HighlightedScripture, content: [String: String]) {
        #if DEBUG
        let printedHighlights = "[\(highlights.map({$0.id}).joined(separator: ","))]"
        print("Syncing highlightedScripture \(scripture.id) with highlights: \(printedHighlights)")
        #endif
        
        #if DEBUG
        let printedOldHighlights = "[\(scripture.highlighted_texts.map({$0.id}).joined(separator: ","))]"
        print("Highlights before sync: \(printedOldHighlights)")
        #endif
        
        updateScriptureContent(scripture, content: content["primary"]!, lang: Constants.Lang.primary)
        updateScriptureContent(scripture, content: content["secondary"]!, lang: Constants.Lang.secondary)
        
        scripture.highlighted_texts.forEach { delete($0) }
        highlights.forEach { write($0) }
        
        #if DEBUG
        let printedNewHighlights = "[\(scripture.highlighted_texts.map({$0.id}).joined(separator: ","))]"
        print("Highlights after sync: \(printedNewHighlights)")
        #endif
        
        if scripture.highlighted_texts.count == 0 {
            let id = scripture.id
            delete(scripture)
            FirestoreManager.shared.removeUserScripture(id: id)
        }
        DispatchQueue.main.async {
            self.delegate?.updateContentView()
        }
    }
    
    func createHighlightedScripture(id: String, date: Date) -> HighlightedScripture? {
        guard let scripture = Utilities.shared.getScripture(id: id) else {
            return nil
        }
        if let highlightedScripture = get(scriptureId: id) {
            #if DEBUG
            print("HighlightedScripture \(id) already exists in Realm so updating its date")
            #endif
            try! realm.write {
                highlightedScripture.date = date as NSDate
            }
            return highlightedScripture
        }
        #if DEBUG
        print("HighlightedScripture \(id) does not exist in Realm so creating new one")
        #endif
        return write(HighlightedScripture(scripture: scripture, date: date as NSDate))
    }
    
    func createHighlight(id: String,
                         text: String,
                         note: String = "",
                         scripture: HighlightedScripture,
                         date: Date) -> HighlightedText {
        return HighlightedText(
            id: id,
            namePrimary: Utilities.shared.generateTitlePrimary(scripture: scripture.scripture),
            nameSecondary: Utilities.shared.generateTitleSecondary(scripture: scripture.scripture),
            text: text,
            note: note,
            highlightedScripture: scripture,
            date: date as NSDate
        )
    }
    
    fileprivate func write(_ scripture: HighlightedScripture) -> HighlightedScripture {
        try! realm.write {
            realm.add(scripture)
            #if DEBUG
            print("Highlighted scripture \(scripture.id) was created in Realm")
            #endif
        }
        return scripture
    }
    
    fileprivate func write(_ highlight: HighlightedText) {
        try! realm.write {
            realm.add(highlight)
        }
        #if DEBUG
        print("Highlight \(highlight.id) was created in Realm")
        #endif
    }
    
    fileprivate func delete(_ scripture: HighlightedScripture) {
        let id = scripture.id
        try! realm.write {
            realm.delete(scripture)
        }
        #if DEBUG
        print("Highlighted scripture \(id) was removed from Realm")
        #endif
    }
    
    fileprivate func delete(_ highlight: HighlightedText) {
        let id = highlight.id
        try! realm.write {
            realm.delete(highlight)
        }
        #if DEBUG
        print("Highlight \(id) was removed from Realm")
        #endif
    }
    
    fileprivate func updateScriptureContent(_ highlightedScripture: HighlightedScripture,
                                           content: String,
                                           lang: String) {
        try! realm.write {
            if lang == Constants.Lang.primary {
                highlightedScripture.scripture.scripture_primary = content
            } else {
                highlightedScripture.scripture.scripture_secondary = content
            }
        }
    }
}
