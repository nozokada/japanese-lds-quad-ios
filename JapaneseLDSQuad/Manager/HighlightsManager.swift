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
    
    var delegate: ContentChangeDelegate?
    
    func get(scriptureId: String) -> HighlightedScripture? {
        return realm.object(ofType: HighlightedScripture.self, forPrimaryKey: scriptureId)
    }
    
    func get(textId: String) -> HighlightedText? {
        return realm.object(ofType: HighlightedText.self, forPrimaryKey: textId)
    }
    
    func getAll(sortBy: String = "date", ascending: Bool = false) -> Results<HighlightedText> {
        return realm.objects(HighlightedText.self).sorted(byKeyPath: sortBy, ascending: ascending)
    }
    
    func add(textId: String, textContent: String, scriptureId: String, scriptureContent: String, language: String) {
        guard let scripture = Utilities.shared.getScripture(id: scriptureId) else {
            return
        }
        let createdAt = Date()
        let highlightedScripture = get(scriptureId: scriptureId) ?? create(scripture: scripture, modifiedAt: createdAt)
        applyHighlightChanges(highlightedScripture, content: scriptureContent, language: language, modifiedAt: createdAt)
        createHighlight(id: textId, text: textContent, scripture: highlightedScripture, modifiedAt: createdAt, sync: true)
    }
    
    func remove(textId: String, content: String, language: String) {
        guard let highlight = get(textId: textId), let highlightedScripture = highlight.highlighted_scripture else {
            return
        }
        applyHighlightChanges(highlightedScripture, content: content, language: language, modifiedAt: Date())
        deleteHighlight(highlight, sync: true)
    }
    
    func syncAdd(textId: String, note: String, text: String, modifiedAt: Date, scriptureId: String, content: [String: String], scriptureModifiedAt: Date) {
        guard let scripture = Utilities.shared.getScripture(id: scriptureId) else {
            return
        }
        let highlightedScripture = get(scriptureId: scriptureId) ?? create(scripture: scripture, modifiedAt: scriptureModifiedAt)
        if highlightedScripture.date.timeIntervalSince1970 > scriptureModifiedAt.timeIntervalSince1970 {
            #if DEBUG
            print("Newer highlighted scripture \(highlightedScripture.id) exists")
            #endif
            return
        }
        applyHighlightChanges(highlightedScripture, content: content["primary"]!, language: Constants.Language.primary, modifiedAt: scriptureModifiedAt)
        applyHighlightChanges(highlightedScripture, content: content["secondary"]!, language: Constants.Language.secondary, modifiedAt: scriptureModifiedAt)
        if let highlight = get(textId: textId) {
            deleteHighlight(highlight)
        }
        createHighlight(id: textId, text: text, note: note, scripture: highlightedScripture, modifiedAt: modifiedAt)
        delegate?.updateContent()
    }
    
    func syncRemove(textId: String, scriptureId: String, content: [String: String], scriptureModifiedAt: Date) {
        guard let highlight = get(textId: textId) else {
            #if DEBUG
            print("Highlight \(textId) does not exist")
            #endif
            return
        }
        if let highlightedScripture = get(scriptureId: scriptureId) {
            applyHighlightChanges(highlightedScripture, content: content["primary"]!, language: Constants.Language.primary, modifiedAt: scriptureModifiedAt)
            applyHighlightChanges(highlightedScripture, content: content["secondary"]!, language: Constants.Language.secondary, modifiedAt: scriptureModifiedAt)
        }
        deleteHighlight(highlight)
        delegate?.updateContent()
    }
    
    func updateNote(textId: String, note: String) {
        guard let highlight = get(textId: textId) else { return }
        let updatedAt = NSDate()
        try! realm.write {
            highlight.note = note
            highlight.date = updatedAt
            highlight.highlighted_scripture.date = updatedAt
        }
        FirestoreManager.shared.addCustomScripture(highlight.highlighted_scripture) {
            FirestoreManager.shared.addHighlight(highlight)
        }
    }
    
    fileprivate func create(scripture: Scripture, modifiedAt: Date) -> HighlightedScripture {
        let highlightedScripture = HighlightedScripture(
            id: scripture.id,
            scripture: scripture,
            date: modifiedAt as NSDate
        )
        try! realm.write {
            realm.add(highlightedScripture)
            #if DEBUG
            print("Highlighted scripture \(scripture.id) was added successfully")
            #endif
        }
        return highlightedScripture
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
    
    fileprivate func createHighlight(id: String, text: String, note: String = "", scripture: HighlightedScripture, modifiedAt: Date, sync: Bool = false) {
        let highlight = HighlightedText(
            id: id,
            namePrimary: Utilities.shared.generateTitlePrimary(scripture: scripture.scripture),
            nameSecondary: Utilities.shared.generateTitleSecondary(scripture: scripture.scripture),
            text: text,
            note: note,
            highlightedScripture: scripture,
            date: modifiedAt as NSDate
        )
        try! realm.write {
            realm.add(highlight)
        }
        #if DEBUG
        print("Highlight \(highlight.id) (for \(highlight.name_primary)) was added successfully")
        #endif
        if sync {
            FirestoreManager.shared.addCustomScripture(scripture) {
                FirestoreManager.shared.addHighlight(highlight)
            }
        }
    }
    
    fileprivate func deleteHighlight(_ highlight: HighlightedText, sync: Bool = false) {
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
            FirestoreManager.shared.addCustomScripture(highlightedScripture) {
                FirestoreManager.shared.removeHighlight(id: id)
            }
        }
    }
    
    fileprivate func deleteHighlightedScriptureIfNeeded(_ highlightedScripture: HighlightedScripture, sync: Bool = false) {
        if highlightedScripture.highlighted_texts.count == 0 {
            let id = highlightedScripture.id
            delete(highlightedScripture)
            if sync {
                FirestoreManager.shared.removeCustomScripture(id: id)
            }
        }
    }
    
    fileprivate func applyHighlightChanges(_ highlightedScripture: HighlightedScripture, content: String, language: String, modifiedAt: Date) {
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
