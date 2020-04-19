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
    
    var delegate: FirestoreManagerDelegate?
    var bookmarkListener: ListenerRegistration?
    
    static let shared = FirestoreManager()
    
    let usersCollection = Firestore.firestore().collection(Constants.CollectionName.users)
    
    var syncEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Constants.Config.sync)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.Config.sync)
        }
    }
    
    func sync() {
        if syncEnabled {
            startSync()
        } else {
            stopSync()
        }
    }
    
    fileprivate func startSync() {
        guard let user = AuthenticationManager.shared.currentUser else {
            return
        }
        
        if Utilities.shared.lastSyncedDate == Date.distantPast {
            print("Do full sync")
            updateLastSyncedDate()
        } else {
            print("Do incremental sync")
        }
        fetchBookmarks(userId: user.uid)
    }
    
    fileprivate func stopSync() {
        bookmarkListener?.remove()
    }
    
    fileprivate func fetchBookmarks(userId: String) {
        let collectionName = Constants.CollectionName.bookmarks
        bookmarkListener = usersCollection.document(userId).collection(collectionName).addSnapshotListener() { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                return
            }
            
            let source = snapshot.metadata.hasPendingWrites ? "<Local>" : "<Server>"
            print(source)
            
            snapshot.documentChanges.forEach { diff in
                let id = diff.document.documentID
                if (diff.type == .removed) {
                    print("Bookmark \(diff.document.documentID) was removed from Firestore")
                    let _ = BookmarksManager.shared.delete(bookmarkId: id)
                }
                if (diff.type == .added || diff.type == .modified) {
                    print("Bookmark \(diff.document.documentID) was added or modified in Firestore")
                    let createdTimestamp = diff.document.data()["createdAt"] as! Timestamp
                    let createdAt = createdTimestamp.dateValue()
                    BookmarksManager.shared.add(scriptureId: id, createdAt: createdAt)
                }
            }
            self.delegate?.firestoreManagerDidFetchBookmarks()
            self.updateLastSyncedDate()
        }
    }
    
    fileprivate func pushBookmarks(userId: String) {
        let bookmarks = BookmarksManager.shared.getAll()
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
        guard let user = AuthenticationManager.shared.currentUser else {
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
                print("Bookmark \(bookmark.id) was successfully added to Firestore")
            }
        }
    }
    
    func deleteBookmark(id: String) {
        guard let user = AuthenticationManager.shared.currentUser else {
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
