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
    
    var targetBook: Book!
    var targetVerse = ""
    var targetChapterId = ""
    var targetScriptureId = ""
    
    var pageIndex = 0
    var relativeOffset: CGFloat = 0
    
    var pageContents = ""
    
    @IBOutlet weak var webView: WKWebView!
    
    var spinner: UIActivityIndicatorView!
    
    var lastTapPoint = CGPoint(x: 0, y: 0)
    var selectedHighlightedTextId = ""
    
    let bookmarkManager = BookmarkManager.shared
    let highlightManager = HighlightManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        realm = try! Realm()
        webView.delegate = self
        webView.loadHTMLString(pageContents, baseURL: Bundle.main.bundleURL)
        addGestureRecognizerToWebView()
        
        spinner = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
        showActivityIndicator()
        setDefaultMenuItems()
    }
    
    func showActivityIndicator() {
        spinner.center = self.view.center
        spinner.style = .medium
        
        if UserDefaults.standard.bool(forKey: Constants.Config.night) {
            spinner.backgroundColor = UIColor(red:0.13, green:0.13, blue:0.15, alpha:1.0)
        }
        spinner.startAnimating()
        self.view.addSubview(spinner)
    }
}

extension ContentViewController: UIWebViewDelegate {
    
    func setDefaultMenuItems() {
        if PurchaseManager.shared.isPurchased {
            let copyVerseTitle = "copyVerseMenuItemLabel".localized
            let copyVerseMenuItem = UIMenuItem(title: copyVerseTitle, action: #selector(self.copyVerseText))
            let highlightTitle = "highlightMenuItemLabel".localized
            let highlightMenuItem = UIMenuItem(title: highlightTitle, action: #selector(self.highlightText))
            UIMenuController.shared.menuItems = [copyVerseMenuItem, highlightMenuItem]
        }
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
        let scriptureId = webView.stringByEvaluatingJavaScript(from: JavaScriptFunctions.getScriptureIdScript())
        if scriptureId.isEmpty { showInvalidSelectedRangeAlert(); return }
        let scriptureLanguage = webView.stringByEvaluatingJavaScript(from: JavaScriptFunctions.getScriptureLanguageScript())
        
        if let scripture = realm.objects(Scripture.self).filter("id = '\(scriptureId)'").first {
            UIPasteboard.general.string = scriptureLanguage == Constants.LanguageCodes.Primary ?
                scripture.scripture_primary_raw : scripture.scripture_secondary_raw
        }
    }
    
    @objc func highlightText() {
        let highlightedTextId = "highlight_" + NSUUID().uuidString
        
        let scriptureId = webView.stringByEvaluatingJavaScript(from: JavaScriptFunctions.getScriptureIdScript())
        if scriptureId.isEmpty { showInvalidSelectedRangeAlert(); return }
        let highlightedText = webView.stringByEvaluatingJavaScript(from: JavaScriptFunctions.getHighlightedTextScript(textId: highlightedTextId))
        if highlightedText.isEmpty { showInvalidSelectedRangeAlert(); return }

        let scriptureContent = webView.stringByEvaluatingJavaScript(from: JavaScriptFunctions.getScriptureContentScript())
        let scriptureLanguage = webView.stringByEvaluatingJavaScript(from: JavaScriptFunctions.getScriptureLanguageScript())
        
        highlightManager.addHighlight(textId: highlightedTextId, textContent: highlightedText,
                                       scriptureId: scriptureId, scriptureContent: scriptureContent,
                                       language: scriptureLanguage)
    }
    
    @objc func editNote() {
        if let viewController = storyboard?.instantiateViewController(withIdentifier: "notes") as? NotesViewController {
            viewController.selectedHighlightedTextId = selectedHighlightedTextId
            let notesNavigationController = MainNavigationController(rootViewController: viewController)
            notesNavigationController.previousNavigationController = self.navigationController
            self.present(notesNavigationController, animated: true, completion: nil)
        }
    }
    
    @objc func unhighlightText() {
        let scriptureContentLanguage = webView.stringByEvaluatingJavaScript(
            from: JavaScriptFunctions.getScriptureContentLanguageScript(textId: selectedHighlightedTextId))
        let scriptureContent = webView.stringByEvaluatingJavaScript(
            from: JavaScriptFunctions.getScriptureContentScript(textId: selectedHighlightedTextId))

        highlightManager.removeHighlight(id: selectedHighlightedTextId,
                                          content: scriptureContent,
                                          contentLanguage: scriptureContentLanguage)
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
        webView.stringByEvaluatingJavaScript(from: JavaScriptFunctions.getBookmarkUpdateScript(verseId: verseId))
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        let eventId = request.url?.lastPathComponent
        var path = (request.url?.pathComponents)!
        
        let rangeToRemove = path.startIndex..<path.firstIndex(of: "Japanese LDS Quad.app")!
        path.removeSubrange(rangeToRemove)
        
        if eventId == "bookmark" {
            toggleBookmark(verseId: path[1])
        }
        else if eventId == "highlight" {
            showHighlightMenuItems(highlightedTextId: path[1])
        }
        else {
            if path.count >= 2 {
                jumpToAnotherContent(path: path)
            }
        }
        return true
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        if targetScriptureId != "" {
            spotlightFoundVerse(verseId: targetScriptureId)
        }
        
        let height = CGFloat(Float(webView.stringByEvaluatingJavaScript(from: "document.documentElement.scrollHeight;")!)!)
        let visibleHeight = webView.scrollView.bounds.size.height
        var offset: CGFloat = 0
        
        offset = targetVerse.isEmpty ? relativeOffset * height : getAnchorOffset()
        if offset >= (height - visibleHeight) {
            offset = height - visibleHeight
        }
        
        webView.scrollView.setContentOffset(CGPoint(x: 0, y: offset), animated: false)
        hideActivityIndicator()
    }
    
    func hideActivityIndicator() {
        spinner.stopAnimating()
    }
    
    func jumpToAnotherContent(path: [String]!) {
        if path.count == 2 { // if the link contains only book name
            if let nextBook = realm.objects(Book.self).filter("link = '\(path[1])'").last {
                if let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.pages) as? PagesViewController {
                    viewController.targetBookName = nextBook.name_primary
                    viewController.targetBook = nextBook
                    viewController.targetChapterId = DataService.shared.getChapterId(bookId: nextBook.id, chapter: 1)
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
                    viewController.targetChapterId = DataService.shared.getChapterId(bookId: nextBook.id, chapter: Int(chapter)!)
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
    
    func getAnchorOffset() -> CGFloat {
        return CGFloat(Float(webView.stringByEvaluatingJavaScript(from: JavaScriptFunctions.getAnchorOffsetScript()))!)
    }
    
    func spotlightFoundVerse(verseId: String) {
        webView.stringByEvaluatingJavaScript(from: JavascriptFunctions.getVerseSpotlightScript(verseId: verseId))
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
