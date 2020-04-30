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
    
    var delegate: AuthenticationManagerDelegate?
    
    static let shared = AuthenticationManager()
    
    var currentUser: User? {
        return Auth.auth().currentUser
    }
    
    func createUser(email: String, password: String, username: String) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            guard let user = authResult?.user else {
                #if DEBUG
                print("Failed to create authentication")
                #endif
                if let error = error {
                    self.handleAuthError(error)
                }
                return
            }
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = username
            changeRequest.commitChanges() { error in
                if let _ = error {
                    #if DEBUG
                    print("Failed to change user display name")
                    #endif
                }
            }
            
            Firestore.firestore().collection(Constants.CollectionName.users).document(user.uid).setData([
                Constants.FieldName.username : username,
                Constants.FieldName.createdTimestamp : FieldValue.serverTimestamp()
            ]) { error in
                if let error = error {
                    #if DEBUG
                    print("Failed to create user")
                    #endif
                    self.handleAuthError(error)
                } else {
                    self.delegate?.authenticationManagerDidSucceed()
                }
            }
        }
    }
    
    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                #if DEBUG
                print("Failed to sign in")
                #endif
                self.handleAuthError(error)
            } else {
                self.delegate?.authenticationManagerDidSucceed()
            }
        }
    }
    
    func signOut(completion: @escaping () -> ()) {
        do {
            try Auth.auth().signOut()
            completion()
        }
        catch let error as NSError {
            handleAuthError(error)
        }
    }
    
    func sendPasswordReset(to email: String) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                #if DEBUG
                print("Failed to send password reset email")
                #endif
                self.handleAuthError(error)
            } else {
                self.delegate?.authenticationManagerDidSucceed()
            }
        }
    }
    
    fileprivate func handleAuthError(_ error: Error) {
        let error = error as NSError
        var message = error.localizedDescription
        if let authErrorCode = AuthErrorCode(rawValue: error.code) {
            message = authErrorCode.getDescription(error: error)
        }
        self.delegate?.authenticationManagerDidReceiveMessage(message)
    }
}
