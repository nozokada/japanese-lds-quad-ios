//
//  AppExtension.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/3/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import Foundation
import StoreKit

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

extension SKProduct {
    
    var regularPrice: String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price)
    }
}
