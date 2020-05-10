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
    var scriptures: Results<Scripture>!
    var contentType = Constants.ContentType.main
    var targetVerse: String?
    var targetChapterId: String!
    
    var currentContentViewController: ContentViewController!
    var currentChapterIndex: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        dataSource = self
        setSettingsBarButton()
        setSpeechBarButton()
        contentType = Utilities.shared.getContentType(targetBook: targetBook)
        scriptures = targetBook.child_scriptures.sorted(byKeyPath: "id")
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
        targetChapterId = Utilities.shared.getChapterIdFromChapterNumber(
            bookId: targetBook.id,
            chapter: targetScriptureData.chapter)
        targetVerse = targetScriptureData.verse
    }
    
    func initData(scripture: Scripture) {
        targetBook = scripture.parent_book
        targetVerse = scripture.verse
        targetBookName = targetBook.name_primary
        targetChapterId = Utilities.shared.getChapterIdFromScripture(scripture: scripture)
    }
    
    fileprivate func setTitle() {
        guard let chapterId = targetChapterId else {
            return
        }
        switch contentType {
        case Constants.ContentType.aux:
            navigationItem.title = scriptures.first?.parent_book.name_primary
        case  Constants.ContentType.gs:
            navigationItem.title = scriptures.filter(
                "verse = 'title' AND id BEGINSWITH '\(chapterId)'").first?.scripture_primary.tagsRemoved
        default:
            guard let bookName = targetBookName else {
                return
            }
            let counter = scriptures.filter(
                "verse = 'counter' AND id BEGINSWITH '\(chapterId)'").first?.scripture_primary ?? ""
            navigationItem.title = "\(bookName) \(counter)"
        }
    }
    
    fileprivate func loadContentViewController() {
        guard let contentViewControllers = [getViewControllerAt(currentChapterIndex)] as? [UIViewController] else {
            return
        }
        setViewControllers(contentViewControllers, direction: .forward, animated: false, completion: nil)
        currentContentViewController = viewControllers?.first as? ContentViewController
    }
    
    fileprivate func getViewControllerAt(_ index: Int) -> ContentViewController? {
        guard let contentViewController = storyboard?.instantiateViewController(
            withIdentifier: Constants.StoryBoardID.content) as? ContentViewController else {
                return nil
        }
        let chapterId = Utilities.shared.getChapterIdFromChapterNumber(bookId: targetBook.id, chapter: index + 1)
        let scriptures = Utilities.shared.getScriptures(chapterId: chapterId)
        let contentBuilder = Utilities.shared.getContentBuilder(scriptures: scriptures, contentType: contentType)
        let contentViewData = ContentViewData(
            index: index,
            builder: contentBuilder,
            chapterId: chapterId,
            verse: chapterId == targetChapterId ? targetVerse : nil)
        contentViewController.initData(contentViewData: contentViewData)
        return contentViewController
    }
    
    fileprivate func saveCurrentRelativeOffset() {
        let offset = currentContentViewController.webView.scrollView.contentOffset.y
        let height = currentContentViewController.webView.scrollView.contentSize.height
        currentContentViewController.relativeOffset = offset / height
    }
}


extension PagesViewController: SettingsViewDelegate {
    
    func reload() {
        saveCurrentRelativeOffset()
        guard let viewControllers = viewControllers else {
            return
        }
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
        guard let speechViewController = getSpeechViewController() else {
            return
        }
        speechViewController.initScripturesToSpeech(chapterId: targetChapterId, scriptures: scriptures)
    }
}

extension PagesViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentViewController = viewController as? ContentViewController else {
            return nil
        }
        let currentIndex = currentViewController.pageIndex
        return currentIndex > 0 ? getViewControllerAt(currentIndex - 1) : nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentViewController = viewController as? ContentViewController else {
            return nil
        }
        let currentIndex = currentViewController.pageIndex
        let lastChapter = Utilities.shared.getChapterNumberFromScriptureId(id: (scriptures.last?.id)!)
        return currentIndex < lastChapter - 1 ? getViewControllerAt(currentIndex + 1) : nil
    }
}

extension PagesViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        saveCurrentRelativeOffset()
        if completed {
            currentContentViewController = viewControllers?.first as? ContentViewController
            currentChapterIndex = currentContentViewController.pageIndex
            targetChapterId = Utilities.shared.getChapterIdFromChapterNumber(
                bookId: targetBook.id,
                chapter: currentChapterIndex + 1)
            setTitle()
            updateScripturesToSpeech()
        }
    }
}
