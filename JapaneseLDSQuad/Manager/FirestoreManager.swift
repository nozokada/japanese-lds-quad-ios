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
    
    let usersCollection = Firestore.firestore().collection("users")
    let bookmarksCollection = Firestore.firestore().collection("bookmarks")
    let highlightedScripturesCollection = Firestore.firestore().collection("highlighted_scriptures")
    let highlightedTextsCollection = Firestore.firestore().collection("highlighted_texts")
    
    func addBookmark(bookmark: Bookmark) {
        guard let user = AuthenticationManager.shared.currentUser else {
            return
        }
        
        usersCollection.document(user.uid).collection("bookmarks").document(bookmark.id).setData([
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
        
        usersCollection.document(user.uid).collection("bookmarks").document(bookmarkId).delete() { error in
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
        getBookmarks(userId: user.uid)
        getHighlightedScriptures(userId: user.uid)
        getHighlightedTexts(userId: user.uid)
        
        UserDefaults.standard.set(Date(), forKey: Constants.Config.synced)
        print(Utilities.shared.lastSyncedDate)
    }
    
    fileprivate func getBookmarks(userId: String) {
        let query = bookmarksCollection.whereField("userId", isEqualTo: userId)
        getDocuments(query: query) { documents, error in
            print("Bookmarks were downloaded")
            if let documents = documents {
                for document in documents {
                    print("\(document.documentID) => \(document.data())")
                }
            }
        }
    }
    
    fileprivate func getHighlightedScriptures(userId: String) {
        let query = highlightedScripturesCollection.whereField("userId", isEqualTo: userId)
        getDocuments(query: query) { documents, error in
            print("Highlighted scriptures were downloaded")
            if let documents = documents {
                for document in documents {
                    print("\(document.documentID) => \(document.data())")
                }
            }
        }
    }
    
    fileprivate func getHighlightedTexts(userId: String) {
        let query = highlightedTextsCollection.whereField("userId", isEqualTo: userId)
        getDocuments(query: query) { documents, error in
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