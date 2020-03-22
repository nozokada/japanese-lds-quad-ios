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
}
