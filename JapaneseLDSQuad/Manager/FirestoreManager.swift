//
//  FirestoreManager.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 4/12/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import Foundation
import RealmSwift
import Firebase

class FirestoreManager {
    
    static let shared = FirestoreManager()
    
    var delegate: FirestoreManagerDelegate?
    var bookmarksListener: ListenerRegistration?
    
    var backupRequired = Utilities.shared.lastSyncedDate == Date.distantPast
    let bookmarksManager = BookmarksManager.shared
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
            let source = snapshot.metadata.hasPendingWrites ? "<Local>" : "<Server>"
            print(source)
            
            snapshot.documentChanges.forEach { diff in
                let id = diff.document.documentID
                if (diff.type == .removed) {
                    print("Bookmark \(diff.document.documentID) was removed from Firestore")
                    let _ = self.bookmarksManager.delete(bookmarkId: id)
                }
                if (diff.type == .added || diff.type == .modified) {
                    print("Bookmark \(diff.document.documentID) was added or modified in Firestore")
                    let createdTimestamp = diff.document.data()["createdAt"] as! Timestamp
                    let createdAt = createdTimestamp.dateValue()
                    self.bookmarksManager.add(scriptureId: id, createdAt: createdAt)
                }
            }
            self.delegate?.firestoreManagerDidFetchBookmarks()
            self.backupBookmarks(userId: userId)
            self.updateLastSyncedDate()
        }
    }
    
    fileprivate func backupBookmarks(userId: String) {
        if !backupRequired {
            return
        }
        backupRequired = false
        let lastSyncedAt = Utilities.shared.lastSyncedDate
        let bookmarks = bookmarksManager.getAll()
        for bookmark in bookmarks {
            if bookmark.date.timeIntervalSince1970 > lastSyncedAt.timeIntervalSince1970 {
                print("Backing up \(bookmark.name_primary)")
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
                print("Error writing document: \(error)")
            } else {
                print("Bookmark \(bookmark.name_primary) was successfully added to Firestore")
            }
        }
    }
    
    func deleteBookmark(id: String) {
        guard let user = AuthenticationManager.shared.currentUser, syncEnabled else {
            return
        }
        let collectionName = Constants.CollectionName.bookmarks
        let bookmarksCollectionRef = usersCollection.document(user.uid).collection(collectionName)
        bookmarksCollectionRef.document(id).delete() { error in
            if let error = error {
                print("Error removing document: \(error)")
            } else {
                print("Bookmark \(id) was successfully removed from Firestore")
            }
        }
    }
    
    fileprivate func updateLastSyncedDate() {
        UserDefaults.standard.set(Date(), forKey: Constants.Config.lastSynced)
        print("Data was synced at \(Utilities.shared.lastSyncedDate)")
    }
}
