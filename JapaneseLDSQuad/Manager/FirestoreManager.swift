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
    
    var bookmarksBackupRequired = Utilities.shared.lastSyncedDate == Date.distantPast
    var highlightsBackupRequired = Utilities.shared.lastSyncedDate == Date.distantPast
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
        bookmarksBackupRequired = true
        highlightsBackupRequired = true
        bookmarksListener?.remove()
        highlightsListener?.remove()
    }
    
    func addBookmark(_ bookmark: Bookmark) {
        guard let user = AuthenticationManager.shared.currentUser, syncEnabled else {
            return
        }
        let userDocument = usersCollection.document(user.uid)
        let bookmarksRef = userDocument.collection(Constants.CollectionName.bookmarks)
        bookmarksRef.document(bookmark.id).setData([
            Constants.FieldName.createdAt: bookmark.date as Date,
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
            Constants.FieldName.text: highlight.text,
            Constants.FieldName.note: highlight.note,
            Constants.FieldName.customScripture: customScripturesRef.document(highlight.highlighted_scripture.id),
            Constants.FieldName.modifiedAt: highlight.date as Date,
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
            Constants.FieldName.content: [
                Constants.FieldName.primary: scripture.scripture.scripture_primary,
                Constants.FieldName.secondary: scripture.scripture.scripture_secondary,
            ],
            Constants.FieldName.modifiedAt: scripture.date as Date,
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
        let lastSyncedAt = Utilities.shared.lastSyncedDate
        syncBookmarks(userId: user.uid) {
            DispatchQueue.main.async {
                self.delegate?.firestoreManagerDidSucceed()
            }
            self.backupBookmarks(userId: user.uid, lastSyncedAt: lastSyncedAt)
            self.updateLastSyncedDate()
        }
        syncHighlights(userId: user.uid) {
            DispatchQueue.main.async {
                self.delegate?.firestoreManagerDidSucceed()
            }
            self.backupHighlights(userId: user.uid, lastSyncedAt: lastSyncedAt)
            self.updateLastSyncedDate()
        }
    }
    
    fileprivate func syncBookmarks(userId: String, completion: (() -> ())? = nil) {
        let userDocument = usersCollection.document(userId)
        bookmarksListener = userDocument.collection(
            Constants.CollectionName.bookmarks).addSnapshotListener() { querySnapshot, error in
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
                let timestamp = document.data()[Constants.FieldName.createdAt] as! Timestamp
                switch diff.type {
                case .added, .modified:
                    #if DEBUG
                    print("Bookmark \(id) was added to/modified in Firestore")
                    #endif
                    BookmarksManager.shared.syncAdd(scriptureId: id, createdAt: timestamp.dateValue())
                case .removed:
                    #if DEBUG
                    print("Bookmark \(id) was deleted from Firestore")
                    #endif
                    BookmarksManager.shared.syncRemove(bookmarkId: id)
                }
            }
            completion?()
            #if DEBUG
            print("------ Server changes for bookmarks were applied ------")
            #endif
        }
    }
    
    fileprivate func backupBookmarks(userId: String, lastSyncedAt: Date) {
        if !bookmarksBackupRequired {
            return
        }
        bookmarksBackupRequired = false
        for bookmark in BookmarksManager.shared.getAll() {
            if bookmark.date.timeIntervalSince1970 > lastSyncedAt.timeIntervalSince1970 {
                #if DEBUG
                print("Backing up bookmark \(bookmark.id) (for \(bookmark.name_primary))")
                #endif
                addBookmark(bookmark)
            }
        }
    }
    
    fileprivate func syncHighlights(userId: String, completion: (() -> ())? = nil) {
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
            var syncedCount = 0
            let changes = snapshot.documentChanges
            changes.forEach { diff in
                let document = diff.document
                let id = document.documentID, data = document.data()
                let note = data[Constants.FieldName.note] as! String
                let text = data[Constants.FieldName.text] as! String
                let timestamp = data[Constants.FieldName.modifiedAt] as! Timestamp

                let customScripture = data[Constants.FieldName.customScripture] as! DocumentReference
                customScripture.getDocument() { documentSnapshot, error in
                    guard let snapshot = documentSnapshot else {
                        return
                    }
                    let customScriptureId = snapshot.documentID
                    let scriptureData = snapshot.data()
                    let content = scriptureData![Constants.FieldName.content] as! [String: String]
                    let scriptureTimestamp = scriptureData![Constants.FieldName.modifiedAt] as! Timestamp
                    switch diff.type {
                    case .added, .modified:
                        #if DEBUG
                        print("Highlight \(id) was added to/modified in Firestore")
                        #endif
                        HighlightsManager.shared.syncAdd(
                            textId: id,
                            note: note,
                            text: text,
                            modifiedAt: timestamp.dateValue(),
                            scriptureId: customScriptureId,
                            content: content,
                            scriptureModifiedAt: scriptureTimestamp.dateValue())
                    case .removed:
                        #if DEBUG
                        print("Highlight \(id) was deleted from Firestore")
                        #endif
                        HighlightsManager.shared.syncRemove(
                            textId: id,
                            scriptureId: customScriptureId,
                            content: content,
                            scriptureModifiedAt: scriptureTimestamp.dateValue())
                    }
                    syncedCount += 1
                    if syncedCount == changes.count {
                        completion?()
                        #if DEBUG
                        print("------ Server changes for highlights were applied ------")
                        #endif
                    }
                }
            }
        }
    }
    
    fileprivate func backupHighlights(userId: String, lastSyncedAt: Date) {
        if !highlightsBackupRequired {
            return
        }
        highlightsBackupRequired = false
        for highlight in HighlightsManager.shared.getAll() {
            if highlight.date.timeIntervalSince1970 > lastSyncedAt.timeIntervalSince1970 {
                #if DEBUG
                print("Backing up highlight \(highlight.id) (for \(highlight.name_primary))")
                #endif
                addCustomScripture(highlight.highlighted_scripture) {
                    self.addHighlight(highlight)
                }
            }
        }
    }
}
