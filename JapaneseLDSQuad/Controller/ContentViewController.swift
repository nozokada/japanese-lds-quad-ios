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
    
    var relativeOffset: CGFloat = 0
    var lastTapPoint = CGPoint(x: 0, y: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        realm = try! Realm()
        webView.delegate = self
        webView.navigationDelegate = self
        webView.evaluateJavaScript(JavaScriptFunctions.getAllFunctions(), completionHandler: nil)
        webView.loadHTMLString(htmlContent, baseURL: Bundle.main.bundleURL)
        showActivityIndicator()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addNoteViewController()
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
}

extension ContentViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        guard var requestUrl = navigationAction.request.url else { return }
        let requestType = requestUrl.lastPathComponent
        
        switch requestType {
        case Bundle.main.bundleURL.lastPathComponent:
            decisionHandler(.allow)
        case Constants.AnnotationType.bookmark:
            decisionHandler(.cancel)
            requestUrl.deleteLastPathComponent()
            toggleBookmark(verseId: requestUrl.lastPathComponent)
        case Constants.AnnotationType.highlight:
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
    
    func spotlightTargetVerses() {
        webView.evaluateJavaScript(JavaScriptSnippets.SpotlightTargetVerses(), completionHandler: nil)
    }
    
    func toggleBookmark(verseId: String) {
        BookmarksManager.shared.updateBookmark(id: verseId)
        webView.evaluateJavaScript(JavaScriptSnippets.toggleBookmarkStatus(verseId: verseId), completionHandler: nil)
    }
    
    func showNote(highlightedTextId: String) {
        if let noteViewController = getNoteViewController() {
            noteViewController.initHighlightedText(id: highlightedTextId)
            noteViewController.show()
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
}

extension ContentViewController: MainWebViewDelegate {
    
    func alert(with title: String, message: String) {
        let alertController = Utilities.shared.alert(title, message: message, handler: nil)
        present(alertController, animated: true)
    }
    
    func showPurchaseViewController() {
        presentPuchaseViewController()
    }
}

extension ContentViewController: HighlightChangeDelegate {
    
    func removeHighlight(id: String) {
        webView.evaluateJavaScript(JavaScriptSnippets.getScriptureLanguage(textId: id)) { result, error in
            guard let language = result as? String else { return }
            self.webView.evaluateJavaScript(JavaScriptSnippets.getScriptureContent(textId: id)) { result, error in
                guard let content = result as? String else { return }
                HighlightsManager.shared.removeHighlight(id: id, content: content, language: language)
                if let noteViewController = self.getNoteViewController() {
                    noteViewController.hide()
                }
            }
        }
    }
}
