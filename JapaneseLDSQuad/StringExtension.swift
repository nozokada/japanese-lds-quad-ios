//
//  StringExtension.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/3/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import Foundation

extension String {
    
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    var tagsRemoved: String{
        return self.replacingOccurrences(of: Constants.RegexPattern.tags, with: "", options: .regularExpression)
    }
}
