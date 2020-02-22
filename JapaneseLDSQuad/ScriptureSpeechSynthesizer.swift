//
//  ScriptureSpeechSynthesizer.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/22/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import Foundation
import AVFoundation
import RealmSwift

class ScriptureSpeechSynthesizer {
    
    var speechSynthesizer: AVSpeechSynthesizer!
    var speechVerses: Results<Scripture>!
    
    init() {
        speechSynthesizer = AVSpeechSynthesizer()
        
    }
}
