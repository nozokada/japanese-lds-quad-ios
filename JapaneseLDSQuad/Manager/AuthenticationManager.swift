//
//  AuthenticationManager.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 3/21/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import Foundation
import Firebase

class AuthenticationManager {
    
    static let shared = AuthenticationManager()
    
    var isAutheticated: Bool {
        return Auth.auth().currentUser != nil
    }
    
    func createUser(email: String, password: String, username: String, completion: @escaping (Bool, Error?) -> ()) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            guard let user = authResult?.user else {
                debugPrint("Failed to create authentication")
                completion(false, error)
                return
            }
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = username
            changeRequest.commitChanges() { error in
                if let _ = error {
                    debugPrint("Failed to change user display name")
                }
            }
            
            Firestore.firestore().collection(Constants.CollectionName.users).document(user.uid).setData([
                Constants.FieldName.username : username,
                Constants.FieldName.createdTimestamp : FieldValue.serverTimestamp()
            ]) { error in
                if let error = error {
                    debugPrint("Failed to create user")
                    completion(false, error)
                } else {
                    completion(true, nil)
                }
            }
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Bool, Error?) -> ()) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                debugPrint("Failed to sign in")
                completion(false, error)
            } else {
                completion(true, nil)
            }
        }
    }
}
