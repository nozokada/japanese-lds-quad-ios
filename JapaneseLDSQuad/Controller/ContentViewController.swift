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

    var targetChapterId: String?
    var targetScriptureId: String?
    var targetVerse: String?
    var htmlContent: String?
    var pageIndex = 0
    var scrollRelativeOffset: CGFloat?
    var noteViewController: NoteViewController?
    
    @IBOutlet weak var webView: MainWebView!
    var spinner: MainIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.delegate = self
        webView.navigationDelegate = self
        webView.evaluateJavaScript(JavaScriptFunctions.load())
        webView.loadHTMLString(htmlContent ?? "", baseURL: Bundle.main.bundleURL)
        showActivityIndicator()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        BookmarksManager.shared.delegate = self
        HighlightsManager.shared.delegate = self
        reload()
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
    
    fileprivate func showActivityIndicator() {
        spinner = MainIndicatorView(parentView: view)
        spinner?.startAnimating()
    }
    
    fileprivate func hideActivityIndicator() {
        spinner?.stopAnimating()
    }
    
    fileprivate func addNoteViewController() {
        guard let viewController = storyboard?.instantiateViewController(
            withIdentifier: Constants.StoryBoardID.notes) as? NoteViewController else {
                return
        }
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
        viewController.setContentViewController(self)
        viewController.view.frame = CGRect(
            x: 0,
            y: view.frame.maxY,
            width: view.frame.width,
            height: view.frame.height)
        noteViewController = viewController
    }
}

extension ContentViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: (WKNavigationActionPolicy) -> Void) {
        guard var requestUrl = navigationAction.request.url else {
            return
        }
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
        reload() {
            self.spotlightTargetVerses()
            self.hideActivityIndicator()
        }
    }
    
    func reload(completion: (() -> ())? = nil) {
        webView.evaluateJavaScript(JavaScriptSnippets.updateAppearance()) { _, _ in
            self.webView.evaluateJavaScript(JavaScriptSnippets.updateSideBySideMode()) { _, _ in
                self.webView.evaluateJavaScript(JavaScriptSnippets.updateDualMode()) { _, _ in
                    self.updateContentView()
                    self.scroll()
                    completion?()
                }
            }
        }
    }
    
    fileprivate func scroll() {
        webView.evaluateJavaScript("document.documentElement.scrollHeight;") { result, error in
            guard let height = result as? CGFloat else { return }
            let visibleHeight = self.webView.scrollView.bounds.size.height
            self.webView.evaluateJavaScript(JavaScriptSnippets.getAnchorOffset()) { result, error in
                var offset: CGFloat = 0
                if let relatvieOffset = self.scrollRelativeOffset {
                    offset = relatvieOffset * height
                } else if let anchorOffset = result as? CGFloat {
                    offset = anchorOffset
                }
                offset  = (offset >= height - visibleHeight) ? height - visibleHeight : offset
                self.webView.evaluateJavaScript("window.scrollTo(0,\(offset));")
            }
        }
    }
    
    func removeHighlight(id: String) {
        webView.evaluateJavaScript(JavaScriptSnippets.getScriptureLang(textId: id)) { result, error in
            guard let lang = result as? String else {
                return
            }
            self.webView.evaluateJavaScript(JavaScriptSnippets.removeHighlight(textId: id)) { result, error in
                guard let content = result as? String else {
                    return
                }
                HighlightsManager.shared.remove(textId: id, content: content, lang: lang)
                self.noteViewController?.hide()
            }
        }
    }
    
    fileprivate func spotlightTargetVerses() {
        webView.evaluateJavaScript(JavaScriptSnippets.SpotlightTargetVerses())
    }
    
    fileprivate func toggleBookmark(verseId: String) {
        BookmarksManager.shared.update(id: verseId)
        webView.evaluateJavaScript(JavaScriptSnippets.updateBookmarkStatus(verseId: verseId))
    }
    
    fileprivate func showNote(highlightedTextId: String) {
        noteViewController?.initHighlightedText(id: highlightedTextId)
        noteViewController?.show()
    }
    
    fileprivate func presentAnotherContent(path: [String]) {
        guard let targetScriptureData = createTargetScriptureDataFromPath(path: path) else {
            return
        }
        if let viewController = storyboard?.instantiateViewController(
            withIdentifier: Constants.StoryBoardID.pages) as? PagesViewController {
            viewController.initData(targetScriptureData: targetScriptureData)
            if targetChapterId == viewController.targetChapterId {
                guard var viewControllers = navigationController?.viewControllers else {
                    return
                }
                viewControllers.removeLast()
                viewControllers.append(viewController)
                navigationController?.setViewControllers(viewControllers, animated: false)
            } else {
                navigationController?.pushViewController(viewController, animated: true)
            }
        }
    }
    
    fileprivate func createTargetScriptureDataFromPath(path: [String]) -> TargetScriptureData? {
        guard var bookId = path.first else {
            return nil
        }
        var chapter = path.count > 1 ? Int(path[1]) ?? 1 : 1
        var verse = path.count > 2
            ? path[2].components(separatedBy: CharacterSet.punctuationCharacters).first!
            : nil
        if bookId == Constants.ContentType.gs {
            guard let v = verse else {
                return nil
            }
            bookId = "gs_\(chapter)"
            chapter = Int(v) ?? 1
            verse = nil
        }
        guard let book = Utilities.shared.getBook(linkName: bookId) else {
            return nil
        }
        return TargetScriptureData(book: book, chapter: chapter, verse: verse)
    }
}

extension ContentViewController: MainWebViewDelegate {
    
    func showAlert(with title: String, message: String) {
        let alertController = Utilities.shared.alert(view: view, title: title, message: message, handler: nil)
        present(alertController, animated: true)
    }
    
    func showPurchaseViewController() {
        presentPuchaseViewController()
    }
}

extension ContentViewController: ContentChangeDelegate {
    
    func updateContentView() {
        guard let chapterId = targetChapterId else {
            return
        }
        noteViewController?.reload()
        for scripture in Utilities.shared.getScriptures(chapterId: chapterId) {
            webView.evaluateJavaScript(JavaScriptSnippets.updateVerse(scripture: scripture))
        }
    }
}
