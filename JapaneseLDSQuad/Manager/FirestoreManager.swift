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
        backupRequired = true
    }
    
    func addBookmark(_ bookmark: Bookmark) {
        guard let user = AuthenticationManager.shared.currentUser, syncEnabled else {
            return
        }
        let collectionName = Constants.CollectionName.bookmarks
        let bookmarksCollectionRef = usersCollection.document(user.uid).collection(collectionName)
        bookmarksCollectionRef.document(bookmark.id).setData([
            "createdAt": bookmark.date as Date,
        ]) { error in
            if let error = error {
                print("Error writing bookmark document: \(error)")
            } else {
                #if DEBUG
                print("Bookmark \(bookmark.name_primary) (\(bookmark.id)) was successfully added to Firestore")
                #endif
            }
        }
    }
    
    func removeBookmark(id: String) {
        guard let user = AuthenticationManager.shared.currentUser, syncEnabled else {
            return
        }
        let collectionName = Constants.CollectionName.bookmarks
        let bookmarksCollectionRef = usersCollection.document(user.uid).collection(collectionName)
        bookmarksCollectionRef.document(id).delete() { error in
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
        let collectionName = Constants.CollectionName.highlights
        let highlightedScripturesCollectionRef = usersCollection.document(user.uid).collection(collectionName)
        highlightedScripturesCollectionRef.document(highlight.id).setData([
            "text": highlight.text,
            "note": highlight.note,
            "createdAt": highlight.date as Date,
        ]) { error in
            if let error = error {
                print("Error writing highlight document: \(error)")
            } else {
                #if DEBUG
                print("Highlight \(highlight.name_primary) (\(highlight.id)) was successfully added to Firestore")
                #endif
            }
        }
    }
    
    func removeHighlight(id: String) {
        guard let user = AuthenticationManager.shared.currentUser, syncEnabled else {
            return
        }
        let collectionName = Constants.CollectionName.highlights
        let highlightedScripturesCollectionRef = usersCollection.document(user.uid).collection(collectionName)
        highlightedScripturesCollectionRef.document(id).delete() { error in
            if let error = error {
                print("Error removing highlight document: \(error)")
            } else {
                #if DEBUG
                print("Highlight \(id) was successfully removed from Firestore")
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
    }
    
    fileprivate func syncBookmarks(userId: String) {
        let collectionName = Constants.CollectionName.bookmarks
        bookmarksListener = usersCollection.document(userId).collection(collectionName).addSnapshotListener() { querySnapshot, error in
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
                case .added:
                    #if DEBUG
                    print("Bookmark \(document.documentID) was added to Firestore")
                    #endif
                    self.bookmarksManager.syncAdd(scriptureId: id, createdAt: createdTimestamp.dateValue())
                case .modified:
                    #if DEBUG
                    print("Bookmark \(document.documentID) was modified in Firestore")
                    #endif
                    self.bookmarksManager.syncAdd(scriptureId: id, createdAt: createdTimestamp.dateValue())
                case .removed:
                    #if DEBUG
                    print("Bookmark \(document.documentID) was deleted from Firestore")
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
    
//    fileprivate func syncHighlightedScriptures(userId: String) {
//        let collectionName = Constants.CollectionName.highlightedScriptures
//        let highlightedScripturesCollectionRef = usersCollection.document(userId).collection(collectionName)
//        getDocuments(query: highlightedScripturesCollectionRef) { documents, error in
//            print("Highlighted scriptures were downloaded")
//            if let documents = documents {
//                for document in documents {
//                    print("\(document.documentID) => \(document.data())")
//                }
//            }
//        }
//    }
//
//    fileprivate func syncHighlightedTexts(userId: String) {
//        let collectionName = Constants.CollectionName.highlightedTexts
//        let highlightedTextsCollectionRef = usersCollection.document(userId).collection(collectionName)
//        getDocuments(query: highlightedTextsCollectionRef) { documents, error in
//            print("Highlighted texts were downloaded")
//            if let documents = documents {
//                for document in documents {
//                    print("\(document.documentID) => \(document.data())")
//                }
//            }
//        }
//    }
//
//    fileprivate func getDocuments(query: Query, completion: @escaping ([DocumentSnapshot]?, Error?) -> ()) {
//        query.getDocuments() { querySnapshot, error in
//            guard let documents = querySnapshot?.documents else {
//                print("Failed to get spot top photo")
//                completion(nil, error)
//                return
//            }
//            completion(documents, nil)
//        }
//    }
}
