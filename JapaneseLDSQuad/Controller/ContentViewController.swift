//
//  ContentViewController.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/3/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit
import RealmSwift
import WebKit

class ContentViewController: UIViewController {

    var realm: Realm!
    var targetChapterId: String!
    var targetScriptureId: String!
    var targetVerse: String?
    var htmlContent: String!
    var pageIndex: Int = 0
    
    @IBOutlet weak var webView: WKWebView!
    var spinner: MainIndicatorView!
    
    var relativeOffset: CGFloat = 0
    var lastTapPoint = CGPoint(x: 0, y: 0)
    var selectedHighlightedTextId = ""
    
    let bookmarkManager = BookmarkManager.shared
    let highlightManager = HighlightManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        realm = try! Realm()
        webView.navigationDelegate = self
        webView.loadHTMLString(htmlContent, baseURL: Bundle.main.bundleURL)
        addGestureRecognizerToWebView()
        addActivityIndicator()
        setDefaultMenuItems()
    }
    
    func initData(index: Int, builder: ContentBuilder, targetChapterId: String, targetVerse: String?) {
        self.targetChapterId = targetChapterId
        self.targetVerse = targetVerse
        pageIndex = index
        htmlContent = builder.build()
    }
    
    func addActivityIndicator() {
        spinner = MainIndicatorView(parentView: view)
        spinner.startAnimating()
    }
    
    func hideActivityIndicator() {
        spinner.stopAnimating()
    }
}

extension ContentViewController: WKNavigationDelegate {
    
//    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//        let request = navigationAction.request
//        let eventId = request.url?.lastPathComponent
//        var path = (request.url?.pathComponents)!
//        
//        let rangeToRemove = path.startIndex..<path.firstIndex(of: "Japanese LDS Quad.app")!
//        path.removeSubrange(rangeToRemove)
//        
//        if eventId == "bookmark" {
//            toggleBookmark(verseId: path[1])
//        } else if eventId == "highlight" {
//            showHighlightMenuItems(highlightedTextId: path[1])
//        } else {
//            if path.count >= 2 {
//                jumpToAnotherContent(path: path)
//            }
//        }
//    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hideActivityIndicator()
//        if targetScriptureId != "" {
//            spotlightFoundVerse(verseId: targetScriptureId)
//        }
//
//        webView.evaluateJavaScript("document.documentElement.scrollHeight;") { result, error in
//            guard let h = NumberFormatter().number(from: String(describing: result)) else { return }
//            let height = CGFloat(truncating: h)
//            let visibleHeight = webView.scrollView.bounds.size.height
//            var offset: CGFloat = 0
//
//            webView.evaluateJavaScript(JavaScriptSnippets.getAnchorOffsetScript()) { result, error in
//                guard let o = NumberFormatter().number(from: String(describing: result)) else { return }
//                let anchorOffset = CGFloat(truncating: o)
//                offset = self.targetVerse.isEmpty ? self.relativeOffset * height : anchorOffset
//                if offset >= (height - visibleHeight) {
//                    offset = height - visibleHeight
//                }
//
//                webView.scrollView.setContentOffset(CGPoint(x: 0, y: offset), animated: false)
//                self.hideActivityIndicator()
//            }
//        }
    }
    
    func showHighlightMenuItems(highlightedTextId: String) {
        becomeFirstResponder()
        let menuController = UIMenuController.shared
        let noteEditTitle = "noteEditMenuItemLabel".localized
        let noteEditMenuItem = UIMenuItem(title: noteEditTitle, action: #selector(self.editNote))
        let unhighlightTitle = "unhighlightMenuItemLabel".localized
        let unhighlightMenuItem = UIMenuItem(title: unhighlightTitle, action: #selector(self.unhighlightText))
        menuController.menuItems = [noteEditMenuItem, unhighlightMenuItem]
        menuController.setTargetRect(CGRect(x: lastTapPoint.x, y: lastTapPoint.y, width: 0, height: 0), in: webView)
        menuController.setMenuVisible(true, animated: true)
        setDefaultMenuItems()
        selectedHighlightedTextId = highlightedTextId
    }
    
    func setDefaultMenuItems() {
        if PurchaseManager.shared.isPurchased {
            let copyVerseTitle = "copyVerseMenuItemLabel".localized
            let copyVerseMenuItem = UIMenuItem(title: copyVerseTitle, action: #selector(self.copyVerseText))
            let highlightTitle = "highlightMenuItemLabel".localized
            let highlightMenuItem = UIMenuItem(title: highlightTitle, action: #selector(self.highlightText))
            UIMenuController.shared.menuItems = [copyVerseMenuItem, highlightMenuItem]
        }
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
        case #selector(copyVerseText), #selector(highlightText),
             #selector(editNote), #selector(unhighlightText):
            return true
        default:
            return false
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    @objc func copyVerseText() {
        var scriptureId: String?
        webView.evaluateJavaScript(JavaScriptSnippets.getScriptureIdScript()) { result, error in
            if let id = result as? String { scriptureId = id } else { return }
            if scriptureId!.isEmpty { self.showInvalidSelectedRangeAlert(); return }
        }
        
        var scriptureLanguage: String?
        webView.evaluateJavaScript(JavaScriptSnippets.getScriptureLanguageScript()) { result, error in
            if let language = result as? String { scriptureLanguage = language } else { return }
        }
        
        if let scripture = realm.objects(Scripture.self).filter("id = '\(scriptureId)'").first {
            UIPasteboard.general.string = scriptureLanguage == Constants.LanguageCode.primary ?
                scripture.scripture_primary_raw : scripture.scripture_secondary_raw
        }
    }
    
    @objc func highlightText() {
        let highlightedTextId = "highlight_" + NSUUID().uuidString
        
        var scriptureId: String?
        webView.evaluateJavaScript(JavaScriptSnippets.getScriptureIdScript()) { result, error in
            if let id = result as? String { scriptureId = id } else { return }
            if scriptureId!.isEmpty { self.showInvalidSelectedRangeAlert(); return }
        }
        
        var highlightedText: String?
        webView.evaluateJavaScript(JavaScriptSnippets.getHighlightedTextScript(textId: highlightedTextId)) { result, error in
            if let text = result as? String { highlightedText = text } else { return }
            if highlightedText!.isEmpty { self.showInvalidSelectedRangeAlert(); return }
        }
        
        var scriptureContent: String?
        webView.evaluateJavaScript(JavaScriptSnippets.getScriptureContentScript()) { result, error in
            if let content = result as? String { scriptureContent = content } else { return }
        }
        
        var scriptureLanguage: String?
        webView.evaluateJavaScript(JavaScriptSnippets.getScriptureLanguageScript()) { result, error in
            if let language = result as? String { scriptureLanguage = language } else { return }
        }
        
//        highlightManager.addHighlight(textId: highlightedTextId, textContent: highlightedText,
//                                       scriptureId: scriptureId, scriptureContent: scriptureContent,
//                                       language: scriptureLanguage)
    }
    
    @objc func unhighlightText() {
        var scriptureContentLanguage: String?
        webView.evaluateJavaScript(JavaScriptSnippets.getScriptureContentLanguageScript(textId: selectedHighlightedTextId)) { result, error in
            if let language = result as? String { scriptureContentLanguage = language } else { return }
        }
        
        var scriptureContent: String?
        webView.evaluateJavaScript(JavaScriptSnippets.getScriptureContentScript(textId: selectedHighlightedTextId)) { result, error in
            if let content = result as? String { scriptureContent = content } else { return }
        }

//        highlightManager.removeHighlight(id: selectedHighlightedTextId, content: scriptureContent, contentLanguage: scriptureContentLanguage)
    }
    
    @objc func editNote() {
//        if let viewController = storyboard?.instantiateViewController(withIdentifier: "notes") as? NotesViewController {
//            viewController.selectedHighlightedTextId = selectedHighlightedTextId
//            let notesNavigationController = MainNavigationController(rootViewController: viewController)
//            notesNavigationController.previousNavigationController = self.navigationController
//            self.present(notesNavigationController, animated: true, completion: nil)
//        }
    }
    
    func showInvalidSelectedRangeAlert() {
        let alertTitle = "InvalidActionAlertTitle".localized
        let alertMessage = "InvalidSelectedRangeAlertMessage".localized
        let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(okAction)
        self.present(alertController, animated: true)
    }
    
    func toggleBookmark(verseId: String) {
        bookmarkManager.addOrRemoveBookmark(id: verseId)
        webView.evaluateJavaScript(JavaScriptSnippets.getBookmarkUpdateScript(verseId: verseId), completionHandler: nil)
    }
    
    func jumpToAnotherContent(path: [String]!) {
        if path.count == 2 { // if the link contains only book name
            if let nextBook = realm.objects(Book.self).filter("link = '\(path[1])'").last {
                if let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.pages) as? PagesViewController {
                    viewController.targetBookName = nextBook.name_primary
                    viewController.targetBook = nextBook
                    viewController.targetChapterId = AppUtility.shared.getChapterId(bookId: nextBook.id, chapter: 1)
                    self.navigationController?.pushViewController(viewController, animated: true)
                }
            }
        }
        else if path.count > 2 { // if the link contains book name and chaper
            var bookId = path[1], chapter = path[2], verse = "0"
            
            if path.count > 3 { // if the link contains verse(s)
                verse = path[3].components(separatedBy: CharacterSet.punctuationCharacters).first!
            }
            
            if bookId == "gs" {
                bookId = "gs_\(chapter)"
                chapter = verse
                verse = "0"
            }
            
            if let nextBook = realm.objects(Book.self).filter("link = '\(bookId)'").sorted(byKeyPath: "id").last {
                if let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.pages) as? PagesViewController {
                    viewController.targetBookName = nextBook.name_primary
                    viewController.targetBook = nextBook
                    viewController.targetChapterId = AppUtility.shared.getChapterId(bookId: nextBook.id, chapter: Int(chapter)!)
                    viewController.targetVerse = verse
                    
                    let navigationController = self.navigationController!
                    if targetChapterId == viewController.targetChapterId {
                        var viewControllers: [UIViewController] = navigationController.viewControllers
                        viewControllers.removeLast()
                        viewControllers.append(viewController)
                        navigationController.setViewControllers(viewControllers, animated: false)
                    }
                    else {
                        navigationController.pushViewController(viewController, animated: true)
                    }
                }
            }
        }
    }
    
    func spotlightFoundVerse(verseId: String) {
        webView.evaluateJavaScript(JavaScriptSnippets.getVerseSpotlightScript(verseId: verseId), completionHandler: nil)
    }
}

extension ContentViewController: UIGestureRecognizerDelegate {
    func addGestureRecognizerToWebView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        tapGestureRecognizer.numberOfTouchesRequired = 1
        tapGestureRecognizer.delegate = self
        webView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc func tapAction(sender: UIGestureRecognizer) {
        let point = sender.location(in: self.view)
        lastTapPoint = point
    }
}
