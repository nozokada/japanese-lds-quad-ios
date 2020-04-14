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
    
    let usersCollection = Firestore.firestore().collection(Constants.CollectionName.users)
        
    func addBookmark(bookmark: Bookmark) {
        guard let user = AuthenticationManager.shared.currentUser else {
            return
        }
        let collectionName = Constants.CollectionName.bookmarks
        let bookmarksCollectionRef = usersCollection.document(user.uid).collection(collectionName)
        bookmarksCollectionRef.document(bookmark.id).setData([
            "createdAt": bookmark.date as NSDate,
        ]) { error in
            if let error = error {
                print("Error writing document: \(error)")
            } else {
                print("Document successfully written!")
            }
        }
    }
    
    func deleteBookmark(bookmarkId: String) {
        guard let user = AuthenticationManager.shared.currentUser else {
            return
        }
        let collectionName = Constants.CollectionName.bookmarks
        let bookmarksCollectionRef = usersCollection.document(user.uid).collection(collectionName)
        bookmarksCollectionRef.document(bookmarkId).delete() { error in
            if let error = error {
                print("Error removing document: \(error)")
            } else {
                print("Document successfully removed!")
            }
        }
    }
    
    func syncData() {
        guard let user = AuthenticationManager.shared.currentUser else {
            return
        }
        syncBookmarks(userId: user.uid)
        syncHighlightedScriptures(userId: user.uid)
        syncHighlightedTexts(userId: user.uid)
        
        UserDefaults.standard.set(Date(), forKey: Constants.Config.synced)
        print(Utilities.shared.lastSyncedDate)
    }
    
    fileprivate func syncBookmarks(userId: String) {
        let collectionName = Constants.CollectionName.bookmarks
        let bookmarksCollectionRef = usersCollection.document(userId).collection(collectionName)
        getDocuments(query: bookmarksCollectionRef) { documents, error in
            print("Bookmarks were downloaded")
            if let documents = documents {
                for document in documents {
                    print("\(document.documentID) => \(document.data())")
                }
            }
        }
    }
    
    fileprivate func syncHighlightedScriptures(userId: String) {
        let collectionName = Constants.CollectionName.highlightedScriptures
        let highlightedScripturesCollectionRef = usersCollection.document(userId).collection(collectionName)
        getDocuments(query: highlightedScripturesCollectionRef) { documents, error in
            print("Highlighted scriptures were downloaded")
            if let documents = documents {
                for document in documents {
                    print("\(document.documentID) => \(document.data())")
                }
            }
        }
    }
    
    fileprivate func syncHighlightedTexts(userId: String) {
        let collectionName = Constants.CollectionName.highlightedTexts
        let highlightedTextsCollectionRef = usersCollection.document(userId).collection(collectionName)
        getDocuments(query: highlightedTextsCollectionRef) { documents, error in
            print("Highlighted texts were downloaded")
            if let documents = documents {
                for document in documents {
                    print("\(document.documentID) => \(document.data())")
                }
            }
        }
    }
    
    fileprivate func getDocuments(query: Query, completion: @escaping ([DocumentSnapshot]?, Error?) -> ()) {
        query.getDocuments() { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Failed to get spot top photo")
                completion(nil, error)
                return
            }
            completion(documents, nil)
        }
    }
}
