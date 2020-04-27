//
//  FirestoreManager.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 4/12/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import Foundation
import Firebase

class FirestoreManager {
    
    static let shared = FirestoreManager()
    
    var delegate: FirestoreManagerDelegate?
    var bookmarksListener: ListenerRegistration?
    var highlightsListener: ListenerRegistration?
    
    var backupRequired = Utilities.shared.lastSyncedDate == Date.distantPast
    let bookmarksManager = BookmarksManager.shared
    let highlightsManager = HighlightsManager.shared
    let usersCollection = Firestore.firestore().collection(Constants.CollectionName.users)
    
    var syncEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Constants.Config.sync)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.Config.sync)
        }
    }
    
    func configure() {
        if syncEnabled {
            startSync()
        }
    }
    
    func enableSync() {
        syncEnabled = true
        startSync()
    }
    
    func disableSync() {
        syncEnabled = false
        bookmarksListener?.remove()
        highlightsListener?.remove()
        backupRequired = true
    }
    
    func addBookmark(_ bookmark: Bookmark) {
        guard let user = AuthenticationManager.shared.currentUser, syncEnabled else {
            return
        }
        let userDocument = usersCollection.document(user.uid)
        let bookmarksRef = userDocument.collection(Constants.CollectionName.bookmarks)
        bookmarksRef.document(bookmark.id).setData([
            "createdAt": bookmark.date as Date,
        ]) { error in
            if let error = error {
                print("Error writing bookmark document: \(error)")
            } else {
                #if DEBUG
                print("Bookmark \(bookmark.id) (for \(bookmark.name_primary)) was successfully added to Firestore")
                #endif
            }
        }
    }
    
    func removeBookmark(id: String) {
        guard let user = AuthenticationManager.shared.currentUser, syncEnabled else {
            return
        }
        let userDocument = usersCollection.document(user.uid)
        let bookmarksRef = userDocument.collection(Constants.CollectionName.bookmarks)
        bookmarksRef.document(id).delete() { error in
            if let error = error {
                print("Error removing bookmark document: \(error)")
            } else {
                #if DEBUG
                print("Bookmark \(id) was successfully removed from Firestore")
                #endif
            }
        }
    }
    
    func addHighlight(_ highlight: HighlightedText) {
        guard let user = AuthenticationManager.shared.currentUser, syncEnabled else {
            return
        }
        let userDocument = usersCollection.document(user.uid)
        let customScripturesRef = userDocument.collection(Constants.CollectionName.customScriptures)
        let highlightsRef = userDocument.collection(Constants.CollectionName.highlights)
        highlightsRef.document(highlight.id).setData([
            "text": highlight.text,
            "note": highlight.note,
            "customScripture": customScripturesRef.document(highlight.highlighted_scripture.id),
            "modifiedAt": highlight.date as Date,
        ]) { error in
            if let error = error {
                print("Error writing highlight document: \(error)")
            } else {
                #if DEBUG
                print("Highlight \(highlight.id) (for \(highlight.name_primary)) was successfully added to Firestore")
                #endif
            }
        }
    }
    
    func addCustomScripture(_ scripture: HighlightedScripture, completion: (() -> ())? = nil) {
        guard let user = AuthenticationManager.shared.currentUser else {
            return
        }
        let userDocument = usersCollection.document(user.uid)
        let customScripturesRef = userDocument.collection(Constants.CollectionName.customScriptures)
        customScripturesRef.document(scripture.id).setData([
            "content": [
                "primary": scripture.scripture.scripture_primary,
                "secondary": scripture.scripture.scripture_secondary,
            ],
            "modifiedAt": scripture.date as Date,
        ]) { error in
            if let error = error {
                print("Error writing custom scripture document: \(error)")
            } else {
                #if DEBUG
                print("Custom scripture \(scripture.id) was successfully added to Firestore")
                #endif
                completion?()
            }
        }
    }
    
    func removeHighlight(id: String) {
        guard let user = AuthenticationManager.shared.currentUser, syncEnabled else {
            return
        }
        let userDocument = usersCollection.document(user.uid)
        let highlightsRef = userDocument.collection(Constants.CollectionName.highlights)
        highlightsRef.document(id).delete() { error in
            if let error = error {
                print("Error removing highlight document: \(error)")
            } else {
                #if DEBUG
                print("Highlight \(id) was successfully removed from Firestore")
                #endif
            }
        }
    }
    
    func removeCustomScripture(id: String) {
        guard let user = AuthenticationManager.shared.currentUser, syncEnabled else {
            return
        }
        let userDocument = usersCollection.document(user.uid)
        let customScripturesRef = userDocument.collection(Constants.CollectionName.customScriptures)
        customScripturesRef.document(id).delete() { error in
            if let error = error {
                print("Error removing custom scripture document: \(error)")
            } else {
                #if DEBUG
                print("Custom scripture \(id) was successfully removed from Firestore")
                #endif
            }
        }
    }
    
    fileprivate func updateLastSyncedDate() {
        UserDefaults.standard.set(Date(), forKey: Constants.Config.lastSynced)
        print("Data was synced at \(Utilities.shared.lastSyncedDate)")
    }
    
    fileprivate func startSync() {
        guard let user = AuthenticationManager.shared.currentUser else {
            return
        }
        syncBookmarks(userId: user.uid)
        syncHighlights(userId: user.uid)
    }
    
    fileprivate func syncHighlights(userId: String) {
        let userDocument = usersCollection.document(userId)
        highlightsListener = userDocument.collection(Constants.CollectionName.highlights).addSnapshotListener() { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                return
            }
            if snapshot.metadata.hasPendingWrites {
                return
            }
            #if DEBUG
            print("------ Server changes for highlights were detected ------")
            #endif
            snapshot.documentChanges.forEach { diff in
                let document = diff.document
                let id = document.documentID, data = document.data()
                let note = data["note"] as! String
                let text = data["text"] as! String
                let modifiedTimestamp = data["modifiedAt"] as! Timestamp

                let customScripture = data["customScripture"] as! DocumentReference
                customScripture.getDocument() { documentSnapshot, error in
                    guard let snapshot = documentSnapshot else {
                        return
                    }
                    let customScriptureId = snapshot.documentID
                    let customScriptureData = snapshot.data()
                    let content = customScriptureData!["content"] as! [String: String]
                    let scriptureModifiedTimestamp = customScriptureData!["modifiedAt"] as! Timestamp
                    
                    switch diff.type {
                    case .added, .modified:
                        #if DEBUG
                        print("Highlight \(id) was added to/modified in Firestore")
                        #endif
                        self.highlightsManager.syncAdd(textId: id, note: note, text: text, modifiedAt: modifiedTimestamp.dateValue(), scriptureId: customScriptureId, content: content, scriptureModifiedAt: scriptureModifiedTimestamp.dateValue())
                    case .removed:
                        #if DEBUG
                        print("Highlight \(id) was deleted from Firestore")
                        #endif
                        self.highlightsManager.syncRemove(textId: id, scriptureId: customScriptureId, content: content, scriptureModifiedAt: scriptureModifiedTimestamp.dateValue())
                    }
                    self.delegate?.firestoreManagerDidFetchHighlights()
                    self.backupHighlights(userId: userId)
                    self.updateLastSyncedDate()
                    #if DEBUG
                    print("------ Server changes for highlights were applied ------")
                    #endif
                }
            }
        }
    }
    
    fileprivate func backupHighlights(userId: String) {
        
    }
    
    fileprivate func syncBookmarks(userId: String) {
        let userDocument = usersCollection.document(userId)
        bookmarksListener = userDocument.collection(Constants.CollectionName.bookmarks).addSnapshotListener() { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                return
            }
            if snapshot.metadata.hasPendingWrites {
                return
            }
            #if DEBUG
            print("------ Server changes for bookmarks were detected ------")
            #endif
            snapshot.documentChanges.forEach { diff in
                let document = diff.document
                let id = document.documentID
                let createdTimestamp = document.data()["createdAt"] as! Timestamp
                switch diff.type {
                case .added, .modified:
                    #if DEBUG
                    print("Bookmark \(id) was added to/modified in Firestore")
                    #endif
                    self.bookmarksManager.syncAdd(scriptureId: id, createdAt: createdTimestamp.dateValue())
                case .removed:
                    #if DEBUG
                    print("Bookmark \(id) was deleted from Firestore")
                    #endif
                    self.bookmarksManager.syncRemove(bookmarkId: id)
                }
            }
            self.delegate?.firestoreManagerDidFetchBookmarks()
            self.backupBookmarks(userId: userId)
            self.updateLastSyncedDate()
            #if DEBUG
            print("------ Server changes for bookmarks were applied ------")
            #endif
        }
    }
    
    fileprivate func backupBookmarks(userId: String) {
        if !backupRequired {
            return
        }
        backupRequired = false
        let lastSyncedAt = Utilities.shared.lastSyncedDate
        for bookmark in bookmarksManager.getAll() {
            if bookmark.date.timeIntervalSince1970 > lastSyncedAt.timeIntervalSince1970 {
                #if DEBUG
                print("Backing up bookmark \(bookmark.name_primary) (\(bookmark.id))")
                #endif
                addBookmark(bookmark)
            }
        }
    }
}
