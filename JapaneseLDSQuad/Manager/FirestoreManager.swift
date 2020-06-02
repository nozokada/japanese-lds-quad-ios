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
                print("Bookmark document \(bookmark.id) was successfully added to Firestore")
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
                print("Bookmark document \(id) was successfully removed from Firestore")
                #endif
            }
        }
    }
    
    func addHighlight(_ highlight: HighlightedText, completion: @escaping (() -> ())) {
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
                print("Highlight document \(highlight.id) was successfully added to Firestore")
                #endif
                completion()
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
                print("Highlight document \(id) was successfully removed from Firestore")
                #endif
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
                print("Highlight \(highlight.id) was successfully added to user scripture \(scripture.id)")
                #endif
            }
        }
    }
    
    func removeFromUserScripture(id: String, scripture: HighlightedScripture, completion: (() -> ())? = nil) {
        guard let user = AuthenticationManager.shared.currentUser, syncEnabled else {
            completion?()
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
    
    func removeUserScripture(id: String) {
        guard let user = AuthenticationManager.shared.currentUser, syncEnabled else {
            return
        }
        let userDocument = usersCollection.document(user.uid)
        let scripturesRef = userDocument.collection(Constants.CollectionName.scriptures)
        scripturesRef.document(id).delete() { error in
            if let error = error {
                print("Error removing user scripture document: \(error)")
            } else {
                #if DEBUG
                print("User scripture \(id) was successfully removed from Firestore")
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
            self.backupBookmarks(userId: user.uid, lastSyncedAt: lastSyncedAt) {
                self.updateLastSyncedDate()
                DispatchQueue.main.async {
                    self.delegate?.firestoreManagerDidSucceed()
                }
            }
        }
        syncHighlights(userId: user.uid) {
            self.backupHighlights(userId: user.uid, lastSyncedAt: lastSyncedAt) {
                self.updateLastSyncedDate()
                DispatchQueue.main.async {
                    self.delegate?.firestoreManagerDidSucceed()
                }
            }
        }
    }
    
    fileprivate func syncBookmarks(userId: String, completion: @escaping () -> ()) {
        let userDocument = usersCollection.document(userId)
        bookmarksListener = userDocument.collection(
            Constants.CollectionName.bookmarks).addSnapshotListener(includeMetadataChanges: true) { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                return
            }
            if snapshot.metadata.hasPendingWrites || snapshot.metadata.isFromCache {
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
                    BookmarksManager.shared.syncAdd(bookmarkId: id, createdAt: timestamp.dateValue())
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
            completion()
        }
    }
    
    fileprivate func backupBookmarks(userId: String, lastSyncedAt: Date, completion: @escaping () -> ()) {
        if !bookmarksBackupRequired {
            completion()
            return
        }
        BookmarksManager.shared.getAll().forEach { bookmark in
            #if DEBUG
            print("Backing up bookmark \(bookmark.id)")
            #endif
            addBookmark(bookmark)
        }
        bookmarksBackupRequired = false
        completion()
    }
    
    fileprivate func syncHighlights(userId: String, completion: @escaping () -> ()) {
        let userDocument = usersCollection.document(userId)
        highlightsListener = userDocument.collection(
            Constants.CollectionName.scriptures).addSnapshotListener(includeMetadataChanges: true) { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                return
            }
            if snapshot.metadata.hasPendingWrites || snapshot.metadata.isFromCache {
                return
            }
            let changes = snapshot.documentChanges
            if changes.count == 0 {
                #if DEBUG
                print("Snapshot listener for highlights fired but there is no change")
                #endif
                completion()
                return
            }
            #if DEBUG
            print("------ Server changes for scriptures were detected ------")
            #endif
            var syncedChangesCount = 0
            changes.forEach { diff in
                let document = diff.document
                let data = document.data()
                let timestamp = data[Constants.FieldName.modifiedAt] as! Timestamp
                guard let scripture = HighlightsManager.shared.getUserScripture(
                    id: document.documentID,
                    date: timestamp.dateValue()) else {
                    return
                }
                let highlights = data[Constants.FieldName.highlights] as! [DocumentReference]
                let content = data[Constants.FieldName.content] as! [String: String]
                self.serializeHighlights(highlights: highlights, scripture: scripture) { highlights in
                    if let highlights = highlights {
                        HighlightsManager.shared.sync(
                            highlights: highlights,
                            userScripture: scripture,
                            content: content)
                    }
                    syncedChangesCount += 1
                    if changes.count == syncedChangesCount {
                        #if DEBUG
                        print("------ Server changes for scriptures were applied ------")
                        #endif
                        completion()
                    }
                }
            }
        }
    }
    
    fileprivate func backupHighlights(userId: String, lastSyncedAt: Date, completion: @escaping () -> ()) {
        if !highlightsBackupRequired {
            completion()
            return
        }
        HighlightsManager.shared.getAll(sortBy: "date").forEach { highlight in
            #if DEBUG
            print("Backing up highlight \(highlight.id)")
            #endif
            addHighlight(highlight) {
                self.addToUserScripture(highlight)
            }
        }
        highlightsBackupRequired = false
        completion()
    }
    
    fileprivate func serializeHighlights(highlights: [DocumentReference],
                                         scripture: HighlightedScripture,
                                         completion: @escaping ([HighlightedText]?) -> ()) {
        if highlights.count == 0 {
            #if DEBUG
            print("There is no highlight for scripture \(scripture.id)")
            #endif
            completion([])
            return
        }
        var highlightsToSync = [HighlightedText]()
        highlights.forEach { highlight in
            highlight.getDocument() { documentSnapshot, error in
                guard let snapshot = documentSnapshot else {
                    completion(nil)
                    return
                }
                guard let data = snapshot.data() else {
                    #if DEBUG
                    print("Highlight \(snapshot.documentID) does not exist anymore in Firestore")
                    #endif
                    completion(nil)
                    return
                }
                let timestamp = data[Constants.FieldName.modifiedAt] as! Timestamp
                highlightsToSync.append(
                    HighlightsManager.shared.createHighlight(
                        id: snapshot.documentID,
                        text: data[Constants.FieldName.text] as! String,
                        note: data[Constants.FieldName.note] as! String,
                        userScripture: scripture,
                        date: timestamp.dateValue()))
                if highlights.count == highlightsToSync.count {
                    completion(highlightsToSync)
                }
            }
        }
    }
}
