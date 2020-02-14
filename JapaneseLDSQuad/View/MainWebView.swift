//
//  MainWebView.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/13/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import WebKit

class MainWebView: WKWebView {
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
        case #selector(copy(_:)), Selector(("_define:")):
            return true
        default:
            return false
        }
    }
}
