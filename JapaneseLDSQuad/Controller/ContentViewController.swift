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
    
    let bookmarkManager = BookmarksManager.shared
    let highlightManager = HighlightsManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        realm = try! Realm()
        webView.navigationDelegate = self
        webView.loadHTMLString(htmlContent, baseURL: Bundle.main.bundleURL)
        addGestureRecognizerToWebView()
        addActivityIndicator()
        setDefaultMenuItems()
    }
    
    func initData(contentViewData: ContentViewData) {
        pageIndex = contentViewData.index
        targetChapterId = contentViewData.chapterId
        targetVerse = contentViewData.verse
        htmlContent = contentViewData.builder.buildContent(targetVerse: targetVerse)
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
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        guard var requestUrl = navigationAction.request.url else { return }
        let requestType = requestUrl.lastPathComponent
        
        switch requestType {
        case Bundle.main.bundleURL.lastPathComponent:
            decisionHandler(.allow)
        case Constants.RequestType.bookmark:
            decisionHandler(.cancel)
            requestUrl.deleteLastPathComponent()
            toggleBookmark(verseId: requestUrl.lastPathComponent)
        case Constants.RequestType.highlight:
            decisionHandler(.cancel)
            requestUrl.deleteLastPathComponent()
            showHighlightMenuItems(highlightedTextId: requestUrl.lastPathComponent)
        default:
            decisionHandler(.cancel)
            let scripturePath = requestUrl.pathComponents.filter {
                e in return !Bundle.main.bundleURL.pathComponents.contains(e)
            }
            presentAnotherContent(path: scripturePath)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("document.documentElement.scrollHeight;") { result, error in
            guard let height = result as? CGFloat else { return }
            let visibleHeight = webView.scrollView.bounds.size.height
            
            webView.evaluateJavaScript(JavaScriptSnippets.getAnchorOffset()) { result, error in
                guard let anchorOffset = result as? CGFloat else { return }
                var offset = self.targetVerse == nil ? self.relativeOffset * height : anchorOffset
                if offset >= (height - visibleHeight) {
                    offset = height - visibleHeight
                }
                webView.evaluateJavaScript("window.scrollTo(0,\(offset))", completionHandler: nil)
                self.spotlightTargetVerses()
                self.hideActivityIndicator()
            }
        }
    }
    
    func presentAnotherContent(path: [String]) {
        guard let targetScriptureData = createTargetScriptureDataFromPath(path: path) else { return }
        if let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.pages) as? PagesViewController {
            viewController.initData(targetScriptureData: targetScriptureData)
            if targetChapterId == viewController.targetChapterId {
                guard var viewControllers = navigationController?.viewControllers else { return }
                viewControllers.removeLast()
                viewControllers.append(viewController)
                navigationController?.setViewControllers(viewControllers, animated: false)
            } else {
                navigationController?.pushViewController(viewController, animated: true)
            }
        }
    }
    
    func createTargetScriptureDataFromPath(path: [String]) -> TargetScriptureData? {
        guard var bookId = path.first else { return nil }
        var chapter = path.count > 1 ? Int(path[1]) ?? 1 : 1
        var verse = path.count > 2 ? path[2].components(separatedBy: CharacterSet.punctuationCharacters).first! : nil
        if bookId == Constants.ContentType.gs {
            guard let v = verse else { return nil }
            bookId = "gs_\(chapter)"
            chapter = Int(v) ?? 1
            verse = nil
        }
        guard let book = realm.objects(Book.self).filter("link = '\(bookId)'").sorted(byKeyPath: "id").last else { return nil }
        return TargetScriptureData(book: book, chapter: chapter, verse: verse)
    }
    
    func spotlightTargetVerses() {
        webView.evaluateJavaScript(JavaScriptSnippets.SpotlightTargetVerses(), completionHandler: nil)
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
        webView.evaluateJavaScript(JavaScriptSnippets.getScriptureId()) { result, error in
            if let id = result as? String { scriptureId = id } else { return }
            if scriptureId!.isEmpty { self.showInvalidSelectedRangeAlert(); return }
        }
        
        var scriptureLanguage: String?
        webView.evaluateJavaScript(JavaScriptSnippets.getScriptureLanguage()) { result, error in
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
        webView.evaluateJavaScript(JavaScriptSnippets.getScriptureId()) { result, error in
            if let id = result as? String { scriptureId = id } else { return }
            if scriptureId!.isEmpty { self.showInvalidSelectedRangeAlert(); return }
        }
        
        var highlightedText: String?
        webView.evaluateJavaScript(JavaScriptSnippets.getHighlightedText(textId: highlightedTextId)) { result, error in
            if let text = result as? String { highlightedText = text } else { return }
            if highlightedText!.isEmpty { self.showInvalidSelectedRangeAlert(); return }
        }
        
        var scriptureContent: String?
        webView.evaluateJavaScript(JavaScriptSnippets.getScriptureContent()) { result, error in
            if let content = result as? String { scriptureContent = content } else { return }
        }
        
        var scriptureLanguage: String?
        webView.evaluateJavaScript(JavaScriptSnippets.getScriptureLanguage()) { result, error in
            if let language = result as? String { scriptureLanguage = language } else { return }
        }
        
//        highlightManager.addHighlight(textId: highlightedTextId, textContent: highlightedText,
//                                       scriptureId: scriptureId, scriptureContent: scriptureContent,
//                                       language: scriptureLanguage)
    }
    
    @objc func unhighlightText() {
        var scriptureContentLanguage: String?
        webView.evaluateJavaScript(JavaScriptSnippets.getScriptureContentLanguage(textId: selectedHighlightedTextId)) { result, error in
            if let language = result as? String { scriptureContentLanguage = language } else { return }
        }
        
        var scriptureContent: String?
        webView.evaluateJavaScript(JavaScriptSnippets.getScriptureContent(textId: selectedHighlightedTextId)) { result, error in
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
        bookmarkManager.addOrDeleteBookmark(id: verseId)
        webView.evaluateJavaScript(JavaScriptSnippets.toggleBookmarkStatus(verseId: verseId), completionHandler: nil)
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
