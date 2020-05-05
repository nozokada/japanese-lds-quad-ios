//
//  PagesViewController.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/3/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit
import RealmSwift
import AVFoundation


class PagesViewController: UIPageViewController {

    var targetBook: Book!
    var targetBookName: String!
    var scripturesInBook: Results<Scripture>!
    var contentType = Constants.ContentType.main
    var targetVerse: String?
    var targetChapterId: String!
    
    var currentContentViewController: ContentViewController!
    var currentChapterIndex: Int!
    var currentRelativeOffset: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        dataSource = self
        setSettingsBarButton()
        setSpeechBarButton()
        contentType = Utilities.shared.getContentType(targetBook: targetBook)
        scripturesInBook = targetBook.child_scriptures.sorted(byKeyPath: "id")
        currentChapterIndex = Utilities.shared.getChapterNumberFromScriptureId(id: targetChapterId) - 1
        setTitle()
        loadContentViewController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addSpeechViewController()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        updateScripturesToSpeech()
    }
    
    func initData(targetScriptureData: TargetScriptureData) {
        targetBook = targetScriptureData.book
        targetBookName = targetScriptureData.book.name_primary
        targetChapterId = Utilities.shared.getChapterIdFromChapterNumber(bookId: targetBook.id, chapter: targetScriptureData.chapter)
        targetVerse = targetScriptureData.verse
    }
    
    func initData(scripture: Scripture) {
        targetBook = scripture.parent_book
        targetVerse = scripture.verse
        targetBookName = targetBook.name_primary
        targetChapterId = Utilities.shared.getChapterIdFromScripture(scripture: scripture)
    }
    
    fileprivate func setTitle() {
        guard let chapterId = targetChapterId else { return }
        switch contentType {
        case Constants.ContentType.aux:
            navigationItem.title = scripturesInBook.first?.parent_book.name_primary
        case  Constants.ContentType.gs:
            navigationItem.title = scripturesInBook.filter("verse = 'title' AND id BEGINSWITH '\(chapterId)'").first?.scripture_primary.tagsRemoved
        default:
            guard let bookName = targetBookName else { return }
            let counter = scripturesInBook.filter("verse = 'counter' AND id BEGINSWITH '\(chapterId)'").first?.scripture_primary ?? ""
            navigationItem.title = "\(bookName) \(counter)"
        }
    }
    
    fileprivate func loadContentViewController() {
        guard let contentViewControllers = [getViewControllerAt(index: currentChapterIndex)] as? [UIViewController] else { return }
        setViewControllers(contentViewControllers, direction: .forward, animated: false, completion: nil)
        currentContentViewController = viewControllers?.first as? ContentViewController
    }
    
    fileprivate func getViewControllerAt(index: Int) -> ContentViewController? {
        let chapterId = Utilities.shared.getChapterIdFromChapterNumber(bookId: targetBook.id, chapter: index + 1)
        let scriptures = Utilities.shared.getScriptures(chapterId: chapterId)
        let contentBuilder = Utilities.shared.getContentBuilder(scriptures: scriptures, contentType: contentType)
        if let contentViewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.content) as? ContentViewController {
            let contentViewData = ContentViewData(
                index: index, builder: contentBuilder, chapterId: chapterId, verse: chapterId == targetChapterId ? targetVerse : nil)
            contentViewController.initData(contentViewData: contentViewData)
            return contentViewController
        }
        return nil
    }
    
    fileprivate func saveCurrentRelativeOffset() {
        let offset = currentContentViewController.webView.scrollView.contentOffset.y
        let height = currentContentViewController.webView.scrollView.contentSize.height
        currentRelativeOffset = offset / height
        currentContentViewController.relativeOffset = currentRelativeOffset
    }
}


extension PagesViewController: SettingsViewDelegate {
    
    func reload() {
        saveCurrentRelativeOffset()
        guard let viewControllers = viewControllers else { return }
        for case let viewController as ContentViewController in viewControllers {
            viewController.reload()
        }
    }
}

extension PagesViewController: SpeechViewDelegate {
    
    func scroll() {
        // TODO: Implement the automatic scroll feature for Scriptures-to-Speech
    }
    
    func updateScripturesToSpeech() {
        if let speechViewController = getSpeechViewController() {
            speechViewController.initScripturesToSpeech(chapterId: targetChapterId, scriptures: scripturesInBook)
        }
    }
}

extension PagesViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let currentViewController = viewController as? ContentViewController {
            let currentIndex = currentViewController.pageIndex
            return currentIndex > 0 ? getViewControllerAt(index: currentIndex - 1) : nil
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let currentViewController = viewController as? ContentViewController {
            let currentIndex = currentViewController.pageIndex
            let lastChapter = Utilities.shared.getChapterNumberFromScriptureId(id: (scripturesInBook.last?.id)!)
            return currentIndex < lastChapter - 1 ? getViewControllerAt(index: currentIndex + 1) : nil
        }
        return nil
    }
}

extension PagesViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if finished && completed {
            currentContentViewController = viewControllers?.first as? ContentViewController
            currentChapterIndex = currentContentViewController.pageIndex
            targetChapterId = Utilities.shared.getChapterIdFromChapterNumber(bookId: targetBook.id, chapter: currentChapterIndex + 1)
            setTitle()
        }
        updateScripturesToSpeech()
    }
}
