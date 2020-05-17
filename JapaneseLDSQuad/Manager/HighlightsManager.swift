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
    
    func add(textId: String,
             textContent: String,
             scriptureId: String,
             scriptureContent: String,
             language: String) {
        guard let scripture = Utilities.shared.getScripture(id: scriptureId) else {
            return
        }
        let createdAt = Date()
        let highlightedScripture = get(scriptureId: scriptureId)
            ?? write(HighlightedScripture(scripture: scripture, date: createdAt as NSDate))
        applyHighlightChanges(
            highlightedScripture,
            content: scriptureContent,
            language: language,
            modifiedAt: createdAt)
        write(createHighlight(
            id: textId,
            text: textContent,
            scripture: highlightedScripture,
            date: createdAt), sync: true)
    }
    
    func remove(textId: String, content: String, language: String) {
        guard let highlight = get(textId: textId),
            let highlightedScripture = highlight.highlighted_scripture else {
            return
        }
        applyHighlightChanges(
            highlightedScripture,
            content: content,
            language: language,
            modifiedAt: Date())
        delete(highlight, sync: true)
    }
    
    func sync(highlights: [HighlightedText],
              scriptureId: String,
              content: [String: String],
              modifiedAt: Date) {
        guard let scripture = Utilities.shared.getScripture(id: scriptureId) else {
            return
        }
        let highlightedScripture = get(scriptureId: scriptureId)
            ?? write(HighlightedScripture(scripture: scripture, date: modifiedAt as NSDate))
        applyHighlightChanges(
            highlightedScripture,
            content: content["primary"]!,
            language: Constants.Language.primary,
            modifiedAt: modifiedAt)
        applyHighlightChanges(
            highlightedScripture,
            content: content["secondary"]!,
            language: Constants.Language.secondary,
            modifiedAt: modifiedAt)
        
        highlightedScripture.highlighted_texts.forEach { delete($0) }
        highlights.forEach { write($0) }
        
        DispatchQueue.main.async {
            self.delegate?.updateContentView()
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
            FirestoreManager.shared.addUserScripture(highlight: highlight)
        }
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
            print("Highlighted scripture \(scripture.id) was added successfully")
            #endif
        }
        return scripture
    }
    
    fileprivate func write(_ highlight: HighlightedText, sync: Bool = false) {
        try! realm.write {
            realm.add(highlight)
        }
        #if DEBUG
        print("Highlight \(highlight.id) (for \(highlight.name_primary)) was added successfully")
        #endif
        if sync {
            FirestoreManager.shared.addHighlight(highlight) {
                FirestoreManager.shared.addUserScripture(highlight: highlight)
            }
        }
    }
    
    fileprivate func delete(_ scripture: HighlightedScripture) {
        let id = scripture.id
        try! realm.write {
            realm.delete(scripture)
        }
        #if DEBUG
        print("Highlighted scripture \(id) was removed successfully")
        #endif
    }
    
    fileprivate func delete(_ highlight: HighlightedText, sync: Bool = false) {
        guard let highlightedScripture = highlight.highlighted_scripture else {
            return
        }
        let id = highlight.id
        let name = highlight.name_primary
        try! realm.write {
            realm.delete(highlight)
        }
        #if DEBUG
        print("Highlight \(id) (for \(name)) was deleted successfully")
        #endif
        if sync {
            FirestoreManager.shared.removeFromUserScripture(
            id: id, scripture: highlightedScripture) {
                FirestoreManager.shared.removeHighlight(id: id)
            }
        }
    }
    
    fileprivate func applyHighlightChanges(_ highlightedScripture: HighlightedScripture,
                                           content: String,
                                           language: String,
                                           modifiedAt: Date) {
        try! realm.write {
            if language == Constants.Language.primary {
                highlightedScripture.scripture.scripture_primary = content
            } else {
                highlightedScripture.scripture.scripture_secondary = content
            }
            highlightedScripture.date = modifiedAt as NSDate
        }
    }
}
