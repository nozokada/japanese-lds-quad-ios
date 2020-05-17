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
    
    func addHighlight(_ highlight: HighlightedText, completion: (() -> ())? = nil) {
        guard let user = AuthenticationManager.shared.currentUser, syncEnabled else {
            return
        }
        let userDocument = usersCollection.document(user.uid)
        let highlightsRef = userDocument.collection(Constants.CollectionName.highlights)
        highlightsRef.document(highlight.id).setData([
            Constants.FieldName.text: highlight.text,
            Constants.FieldName.note: highlight.note,
            Constants.FieldName.modifiedAt: highlight.date as Date,
        ]) { error in
            if let error = error {
                print("Error writing highlight document: \(error)")
            } else {
                #if DEBUG
                print("Highlight \(highlight.id) (for \(highlight.name_primary)) was successfully added to Firestore")
                #endif
                completion?()
            }
        }
    }
    
    func addToUserScripture(_ highlight: HighlightedText) {
        guard let user = AuthenticationManager.shared.currentUser, syncEnabled else {
            return
        }
        guard let scripture = highlight.highlighted_scripture else {
            return
        }
        let userDocument = usersCollection.document(user.uid)
        let scripturesRef = userDocument.collection(Constants.CollectionName.scriptures)
        let highlightsRef = userDocument.collection(Constants.CollectionName.highlights)
        scripturesRef.document(scripture.id).setData([
            Constants.FieldName.content: [
                Constants.FieldName.primary: scripture.scripture.scripture_primary,
                Constants.FieldName.secondary: scripture.scripture.scripture_secondary,
            ],
            Constants.FieldName.modifiedAt: scripture.date as Date,
            Constants.FieldName.highlights: FieldValue.arrayUnion([highlightsRef.document(highlight.id)]),
        ], merge: true) { error in
            if let error = error {
                #if DEBUG
                print("Error adding highlight \(highlight.id) to user scripture \(scripture.id): \(error)")
                #endif
            } else {
                #if DEBUG
                print("Highlight \(highlight.id) was successfully added user scripture \(scripture.id)")
                #endif
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
    
    func removeFromUserScripture(id: String, scripture: HighlightedScripture, completion: (() -> ())? = nil) {
        guard let user = AuthenticationManager.shared.currentUser, syncEnabled else {
            return
        }
        let userDocument = usersCollection.document(user.uid)
        let scripturesRef = userDocument.collection(Constants.CollectionName.scriptures)
        let highlightsRef = userDocument.collection(Constants.CollectionName.highlights)
        scripturesRef.document(scripture.id).updateData([
            Constants.FieldName.content: [
                Constants.FieldName.primary: scripture.scripture.scripture_primary,
                Constants.FieldName.secondary: scripture.scripture.scripture_secondary,
            ],
            Constants.FieldName.highlights: FieldValue.arrayRemove([highlightsRef.document(id)]),
            Constants.FieldName.modifiedAt: scripture.date as Date,
        ]) { error in
            if let error = error {
                print("Error removing highlight \(id) from user scripture \(scripture.id): \(error)")
            } else {
                #if DEBUG
                print("Highlight \(id) was successfully removed from user scripture \(scripture.id)")
                #endif
                completion?()
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
//            self.backupHighlights(userId: user.uid, lastSyncedAt: lastSyncedAt)
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
            #if DEBUG
            print("------ Server changes for bookmarks were applied ------")
            #endif
            completion?()
        }
    }
    
    fileprivate func backupBookmarks(userId: String, lastSyncedAt: Date) {
        if !bookmarksBackupRequired {
            return
        }
        bookmarksBackupRequired = false
        for bookmark in BookmarksManager.shared.getAll() {
            #if DEBUG
            print("Backing up bookmark \(bookmark.id) (for \(bookmark.name_primary))")
            #endif
            addBookmark(bookmark)
        }
    }
    
    fileprivate func syncHighlights(userId: String, completion: (() -> ())? = nil) {
        let userDocument = usersCollection.document(userId)
        highlightsListener = userDocument.collection(Constants.CollectionName.scriptures)
            .addSnapshotListener() { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                return
            }
            if snapshot.metadata.hasPendingWrites {
                return
            }
            let changes = snapshot.documentChanges
            if changes.count == 0 {
                completion?()
                return
            }
            #if DEBUG
            print("------ Server changes for scriptures were detected ------")
            #endif
            var syncedCount = 0
            changes.forEach { diff in
                let document = diff.document
                let id = document.documentID
                let data = document.data()
                guard let highlights = data[Constants.FieldName.highlights] as? [DocumentReference] else {
                    #if DEBUG
                    print("Highlights field does not exist")
                    #endif
                    return
                }
                let timestamp = data[Constants.FieldName.modifiedAt] as! Timestamp
                let content = data[Constants.FieldName.content] as! [String: String]
                self.serializeHighlights(highlights: highlights, scriptureId: id) { highlights in
                    HighlightsManager.shared.sync(
                        highlights: highlights,
                        scriptureId: id,
                        content: content,
                        modifiedAt: timestamp.dateValue())
                    syncedCount += 1
                    if syncedCount == changes.count {
                        #if DEBUG
                        print("------ Server changes for highlights were applied ------")
                        #endif
                        completion?()
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
        for highlight in HighlightsManager.shared.getAll(sortBy: "date") {
            #if DEBUG
            print("Backing up highlight \(highlight.id) (for \(highlight.name_primary))")
            #endif
            addHighlight(highlight) {
                self.addToUserScripture(highlight)
            }
        }
    }
    
    fileprivate func serializeHighlights(highlights: [DocumentReference],
                                         scriptureId: String,
                                         completion: (([HighlightedText]) -> ())? = nil) {
        guard let scripture = HighlightsManager.shared.get(scriptureId: scriptureId) else {
            return
        }
        var realmHighlights = [HighlightedText]()
        for highlight in highlights {
            highlight.getDocument() { documentSnapshot, error in
                guard let snapshot = documentSnapshot else {
                    return
                }
                let id = snapshot.documentID
                let data = snapshot.data()
                let note = data?[Constants.FieldName.note] as! String
                let text = data?[Constants.FieldName.text] as! String
                let timestamp = data?[Constants.FieldName.modifiedAt] as! Timestamp
                realmHighlights.append(
                    HighlightsManager.shared.createHighlight(
                        id: id,
                        text: text,
                        note: note,
                        scripture: scripture,
                        date: timestamp.dateValue()))
                if highlights.count == realmHighlights.count {
                    completion?(realmHighlights)
                }
            }
        }
    }
}
