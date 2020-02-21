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
    
    @IBOutlet weak var webView: MainWebView!
    var spinner: MainIndicatorView!
    var notesView: NotesViewController!
    
    var relativeOffset: CGFloat = 0
    var lastTapPoint = CGPoint(x: 0, y: 0)
    var selectedHighlightedTextId = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        realm = try! Realm()
        webView.navigationDelegate = self
        webView.evaluateJavaScript(JavaScriptFunctions.getAllFunctions(), completionHandler: nil)
        webView.loadHTMLString(htmlContent, baseURL: Bundle.main.bundleURL)
        showActivityIndicator()
        setDefaultMenuItems()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addBottomSheetNotesView()
    }
    
    func initData(contentViewData: ContentViewData) {
        pageIndex = contentViewData.index
        targetChapterId = contentViewData.chapterId
        targetVerse = contentViewData.verse
        htmlContent = contentViewData.builder.buildContent(targetVerse: targetVerse)
    }
    
    func showActivityIndicator() {
        spinner = MainIndicatorView(parentView: view)
        spinner.startAnimating()
    }
    
    func hideActivityIndicator() {
        spinner.stopAnimating()
    }
    
    func addBottomSheetNotesView() {
        guard let notesViewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.notes) as? NotesViewController else { return }
        addChild(notesViewController)
        view.addSubview(notesViewController.view)
        notesViewController.didMove(toParent: self)
        
        let height = view.frame.height
        let width  = view.frame.width
        notesViewController.view.frame = CGRect(x: 0, y: view.frame.maxY, width: width, height: height)
        notesView = notesViewController
    }
    
    func showBottomSheetNotesView() {
        notesView.show()
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
            toggleBookmarkStatus(verseId: requestUrl.lastPathComponent)
        case Constants.RequestType.highlight:
            decisionHandler(.cancel)
            requestUrl.deleteLastPathComponent()
            showNote(highlightedTextId: requestUrl.lastPathComponent)
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
                webView.evaluateJavaScript("window.scrollTo(0,\(offset));", completionHandler: nil)
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
    
    func showNote(highlightedTextId: String) {
        notesView.initHighlightedText(id: highlightedTextId)
        notesView.show()
    }
    
    func setDefaultMenuItems() {
        if PurchaseManager.shared.isPurchased {
            let copyVerseMenuItem = UIMenuItem(title: "copyVerseMenuItemLabel".localized, action: #selector(copyVerseText))
            let highlightMenuItem = UIMenuItem(title: "highlightMenuItemLabel".localized, action: #selector(highlightText))
            UIMenuController.shared.menuItems = [copyVerseMenuItem, highlightMenuItem]
        }
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
        case #selector(copyVerseText), #selector(highlightText):
            return true
        default:
            return false
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    func showInvalidSelectedRangeAlert() {
        let alertTitle = "InvalidActionAlertTitle".localized
        let alertMessage = "InvalidSelectedRangeAlertMessage".localized
        let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(okAction)
        self.present(alertController, animated: true)
    }
    
    func toggleBookmarkStatus(verseId: String) {
        BookmarksManager.shared.addOrDeleteBookmark(id: verseId)
        webView.evaluateJavaScript(JavaScriptSnippets.toggleBookmarkStatus(verseId: verseId), completionHandler: nil)
    }
    
    @objc func copyVerseText() {
        webView.evaluateJavaScript(JavaScriptSnippets.getScriptureId()) { result, error in
            guard let scriptureId = result as? String else { return }
            if scriptureId.isEmpty { self.showInvalidSelectedRangeAlert(); return }
            self.webView.evaluateJavaScript(JavaScriptSnippets.getScriptureLanguage()) { result, error in
                guard let scriptureLanguage = result as? String else { return }
                guard let scripture = self.realm.objects(Scripture.self).filter("id = '\(scriptureId)'").first else { return }
                UIPasteboard.general.string = scriptureLanguage == Constants.LanguageCode.primary
                    ? scripture.scripture_primary_raw
                    : scripture.scripture_secondary_raw
            }
        }
    }
    
    @objc func highlightText() {
        let highlightedTextId = Constants.Prefix.highlight + NSUUID().uuidString
        webView.evaluateJavaScript(JavaScriptSnippets.getScriptureId()) { result, error in
            guard let scriptureId = result as? String else { return }
            if scriptureId.isEmpty { self.showInvalidSelectedRangeAlert(); return }
            self.webView.evaluateJavaScript(JavaScriptSnippets.getTextToHighlight(textId: highlightedTextId)) { result, error in
                guard let highlightedText = result as? String else { return }
                if highlightedText.isEmpty { self.showInvalidSelectedRangeAlert(); return }
                self.webView.evaluateJavaScript(JavaScriptSnippets.getScriptureContent()) { result, error in
                    guard let scriptureContent = result as? String else { return }
                    self.webView.evaluateJavaScript(JavaScriptSnippets.getScriptureLanguage()) { result, error in
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
    
    @objc func unhighlightText() {
        webView.evaluateJavaScript(JavaScriptSnippets.getScriptureLanguage(textId: self.selectedHighlightedTextId)) { result, error in
            guard let language = result as? String else { return }
            self.webView.evaluateJavaScript(JavaScriptSnippets.getScriptureContent(textId: self.selectedHighlightedTextId)) { result, error in
                guard let content = result as? String else { return }
                HighlightsManager.shared.removeHighlight(id: self.selectedHighlightedTextId, content: content, language: language)
            }
        }
    }
}
