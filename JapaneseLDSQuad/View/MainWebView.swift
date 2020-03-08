//
//  MainWebView.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/13/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import WebKit
import RealmSwift

class MainWebView: WKWebView {
    
    var delegate: MainWebViewDelegate?
    
    override func awakeFromNib() {
        setCustomMenuItems()
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
        case #selector(copy(_:)), Selector(("_define:")), #selector(copyVerseText), #selector(highlightText):
            return true
        default:
            return false
        }
    }
    
    func setCustomMenuItems() {
        let copyVerseMenuItem = UIMenuItem(title: "copyVerseMenuItemLabel".localized, action: #selector(copyVerseText))
        let highlightMenuItem = UIMenuItem(title: "highlightMenuItemLabel".localized, action: #selector(highlightText))
        UIMenuController.shared.menuItems = [copyVerseMenuItem, highlightMenuItem]
    }
    
    func alert(message: String) {
        self.delegate?.showAlert(with: "InvalidActionAlertTitle".localized, message: message)
    }
    
    @objc func copyVerseText() {
        if !PurchaseManager.shared.allFeaturesUnlocked {
            delegate?.showPurchaseViewController()
            return
        }
        
        evaluateJavaScript(JavaScriptSnippets.getScriptureId()) { result, error in
            guard let scriptureId = result as? String else {
                self.alert(message: "InvalidCopyRangeAlertMessage".localized)
                return
            }
            self.evaluateJavaScript(JavaScriptSnippets.getScriptureLanguage()) { result, error in
                guard let scriptureLanguage = result as? String else { return }
                guard let realm = try? Realm() else { return }
                guard let scripture = realm.objects(Scripture.self).filter("id = '\(scriptureId)'").first else { return }
                UIPasteboard.general.string = scriptureLanguage == Constants.Language.primary
                    ? scripture.scripture_primary_raw
                    : scripture.scripture_secondary_raw
            }
        }
    }
    
    @objc func highlightText() {
        if !PurchaseManager.shared.allFeaturesUnlocked {
            delegate?.showPurchaseViewController()
            return
        }
        
        let highlightedTextId = Constants.Prefix.highlight + NSUUID().uuidString
        evaluateJavaScript(JavaScriptSnippets.getScriptureId()) { result, error in
            guard let scriptureId = result as? String else {
                self.alert(message: "InvalidHighlightRangeAlertMessage".localized)
                return
            }
            self.evaluateJavaScript(JavaScriptSnippets.getTextToHighlight(textId: highlightedTextId)) { result, error in
                guard let highlightedText = result as? String else {
                    self.alert(message:"InvalidHighlightRangeAlertMessage".localized)
                    return
                }
                self.evaluateJavaScript(JavaScriptSnippets.getScriptureContent()) { result, error in
                    guard let scriptureContent = result as? String else { return }
                    self.evaluateJavaScript(JavaScriptSnippets.getScriptureLanguage()) { result, error in
                        guard let language = result as? String else { return }
                        HighlightsManager.shared.addHighlight(textId: highlightedTextId,
                                                              textContent: highlightedText,
                                                              scriptureId: scriptureId,
                                                              scriptureContent: scriptureContent,
                                                              language: language)
                    }
                }
            }
        }
    }
}
