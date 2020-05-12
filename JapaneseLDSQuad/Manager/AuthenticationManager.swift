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
                print("User creation for \(email) was failed")
                #endif
                if let error = error {
                    self.handleAuthError(error)
                }
                return
            }
            #if DEBUG
            print("User creation for \(email) was successful")
            #endif
            self.changeDisplayName(user: user, username: username) {
                self.createUserData(user: user) {
                    DispatchQueue.main.async {
                        self.delegate?.authenticationManagerDidSucceed()
                    }
                }
            }
        }
    }
    
    func changeDisplayName(user: User, username: String, completion: (() -> ())? = nil) {
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = username
        changeRequest.commitChanges() { error in
            if let error = error {
                #if DEBUG
                print("Display name \(username) was not added: \(error.localizedDescription)")
                #endif
            }
            #if DEBUG
            print("Display name \(username) was successfully added")
            #endif
            completion?()
        }
    }
    
    func createUserData(user: User, completion: (() -> ())? = nil) {
        let username = user.displayName ?? user.uid
        Firestore.firestore().collection(Constants.CollectionName.users).document(user.uid).setData([
            Constants.FieldName.username : username,
            Constants.FieldName.createdAt : FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                #if DEBUG
                print("User data for \(username) was not added: \(error.localizedDescription)")
                #endif
                return
            }
            #if DEBUG
            print("User data for \(username) was successfully added")
            #endif
            completion?()
        }
    }
    
    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                #if DEBUG
                print("Sign in failed")
                #endif
                self.handleAuthError(error)
            } else {
                #if DEBUG
                print("Sign in succeeded")
                #endif
                DispatchQueue.main.async {
                    self.delegate?.authenticationManagerDidSucceed()
                }
            }
        }
    }
    
    func signOut(completion: @escaping () -> ()) {
        do {
            try Auth.auth().signOut()
            FirestoreManager.shared.disableSync()
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
                print("Password reset email was not sent to \(email)")
                #endif
                self.handleAuthError(error)
            } else {
                #if DEBUG
                print("Password reset email was successfully sent to \(email)")
                #endif
                DispatchQueue.main.async {
                    self.delegate?.authenticationManagerDidSucceed()
                }
            }
        }
    }
    
    fileprivate func handleAuthError(_ error: Error) {
        let error = error as NSError
        var message = error.localizedDescription
        if let authErrorCode = AuthErrorCode(rawValue: error.code) {
            message = authErrorCode.getDescription(error: error)
        }
        DispatchQueue.main.async {
            self.delegate?.authenticationManagerDidReceiveMessage(message)
        }
    }
}
