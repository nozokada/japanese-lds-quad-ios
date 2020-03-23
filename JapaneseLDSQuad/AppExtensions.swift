//
//  AppExtensions.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/3/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import AVFoundation
import StoreKit
import Firebase

extension String {
    
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    var tagsRemoved: String {
        return replacingOccurrences(of: Constants.RegexPattern.tags, with: "", options: .regularExpression)
    }
    
    var verseAfterColonRemoved: String {
        return replacingOccurrences(of: "[：|:].*", with: "", options: .regularExpression)
    }
}

extension AVSpeechUtterance {
    
    var speakingPrimary: Bool {
        return voice?.language == Constants.Language.primarySpeech
    }
    
    var speakingSecondary: Bool {
        return voice?.language == Constants.Language.secondarySpeech
    }
}

extension SKProduct {
    
    var regularPrice: String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price)
    }
}
