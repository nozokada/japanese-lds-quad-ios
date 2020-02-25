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
        contentType = AppUtility.shared.getContentType(targetBook: targetBook)
        scripturesInBook = targetBook.child_scriptures.sorted(byKeyPath: "id")
        currentChapterIndex = AppUtility.shared.getChapterNumberFromScriptureId(id: targetChapterId) - 1
        currentContentViewController = getViewControllerAt(index: currentChapterIndex)
        setTitle()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updatePageContentView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addSpeechViewController()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        targetVerse = nil
        setCurrentRelativeOffset()
//        stopSpeaking()
    }
    
    func initData(targetScriptureData: TargetScriptureData) {
        targetBook = targetScriptureData.book
        targetBookName = targetScriptureData.book.name_primary
        targetChapterId = AppUtility.shared.getChapterIdFromChapterNumber(bookId: targetBook.id, chapter: targetScriptureData.chapter)
        targetVerse = targetScriptureData.verse
    }
    
    func initData(scripture: Scripture) {
        targetBook = scripture.parent_book
        targetVerse = scripture.verse
        targetBookName = targetBook.name_primary
        targetChapterId = AppUtility.shared.getChapterIdFromScripture(scripture: scripture)
    }
    
    func updatePageContentView() {
        guard let contentViewControllers = [getViewControllerAt(index: currentChapterIndex)] as? [UIViewController] else { return }
        setViewControllers(contentViewControllers, direction: .forward, animated: false, completion: nil)
        currentContentViewController = viewControllers?.last as? ContentViewController
        currentContentViewController.relativeOffset = currentRelativeOffset
    }
    
    func getViewControllerAt(index: Int) -> ContentViewController? {
        let chapterId = AppUtility.shared.getChapterIdFromChapterNumber(bookId: targetBook.id, chapter: index + 1)
        let scriptures = scripturesInBook.filter("id BEGINSWITH '\(chapterId)'").sorted(byKeyPath: "id")
        let contentBuilder = AppUtility.shared.getContentBuilder(scriptures: scriptures, contentType: contentType)
        if let contentViewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.content) as? ContentViewController {
            let contentViewData = ContentViewData(
                index: index, builder: contentBuilder, chapterId: targetChapterId, verse: chapterId == targetChapterId ? targetVerse: nil)
            contentViewController.initData(contentViewData: contentViewData)
            return contentViewController
        }
        return nil
    }
    
    func setTitle() {
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
    
    func setCurrentRelativeOffset() {
        let offset = currentContentViewController.webView.scrollView.contentOffset.y
        let height = currentContentViewController.webView.scrollView.contentSize.height
        currentRelativeOffset = offset / height
    }
}


extension PagesViewController: SettingsChangeDelegate {
    
    func reload() {
        setCurrentRelativeOffset()
        updatePageContentView()
        
    }
}

extension PagesViewController: ScriptureToSpeechDelegate {
    
    func move() {
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
            let lastChapter = AppUtility.shared.getChapterNumberFromScriptureId(id: (scripturesInBook.last?.id)!)
            return currentIndex < lastChapter - 1 ? getViewControllerAt(index: currentIndex + 1) : nil
        }
        return nil
    }
}

extension PagesViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if finished && completed {
            currentContentViewController = pageViewController.viewControllers?[0] as! ContentViewController?
            currentChapterIndex = currentContentViewController.pageIndex
            targetChapterId = AppUtility.shared.getChapterIdFromChapterNumber(bookId: targetBook.id, chapter: currentChapterIndex + 1)
            setTitle()
        }
        targetVerse = nil
//        loadSpeechVerses()
//        stopSpeaking()
    }
}

//extension ContentViewController: AVSpeechSynthesizerDelegate {
//
//    @objc func speechPlayButtonTapped(_ sender: UIButton) {
//        if speechSynthesizer.isPaused {
//            continueSpeaking()
//        }
//        else if speechSynthesizer.isSpeaking {
//            pauseSpeaking()
//        }
//        else {
//            startSpeaking()
//        }
//    }
//
//    @objc func speechForwardButtonTapped(_ sender: UIButton) {
//        currentSpokenVerseIndex += 1
//        if currentSpokenVerseIndex < speechVerses.count {
//            speechSynthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
//            speakCurrentVerseNumber()
//            startSpeaking()
//        }
//        else {
//            currentSpokenVerseIndex -= 1
//        }
//    }
//
//    @objc func speechBackButtonTapped(_ sender: UIButton) {
//        speechSynthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
//        currentSpokenVerseIndex -= 1
//        if currentSpokenVerseIndex < 0 {
//            currentSpokenVerseIndex += 1
//        }
//        speakCurrentVerseNumber()
//        startSpeaking()
//    }
//
//    func loadSpeechVerses() {
//        speechVerses = scripturesList.filter("id BEGINSWITH '\(targetChapterId)' AND NOT verse IN {'title', 'counter', 'preface', 'intro', 'summary', 'date'}").sorted(byKeyPath: "id")
//        currentSpokenVerseIndex = 0
//    }
//
//    func speakCurrentVerseNumber() {
//        let verseNumber = speechVerses[currentSpokenVerseIndex].verse
//        let utterance = AVSpeechUtterance(string: "\(verseNumber)")
//        utterance.voice = AVSpeechSynthesisVoice(language: Constants.LanguageCodes.PrimarySpeech)
//        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 1.1
//        speechSynthesizer.speak(utterance)
//    }
//
//    func speakCurrentVerse(langCode: String) {
//        if speechActive {
//            let spokenVerse = speechVerses[currentSpokenVerseIndex]
//            let speechText = langCode == Constants.LanguageCodes.PrimarySpeech ?
//                SpeechCorrectionUtility.correctPrimaryLanguage(speechText: spokenVerse.scripture_primary_raw) :
//                SpeechCorrectionUtility.correctSecondaryLanguage(speechText: spokenVerse.scripture_secondary_raw)
//
//            speechQueue.async {
//                let utterance = AVSpeechUtterance(string: speechText)
//                utterance.voice = AVSpeechSynthesisVoice(language: langCode)
//                utterance.rate = AVSpeechUtteranceDefaultSpeechRate
//                self.speechSynthesizer.speak(utterance)
//            }
//        }
//    }
//
//    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
//        let englishEnabled = UserDefaults.standard.bool(forKey: Constants.Configs.Dual)
//        if utterance.rate != AVSpeechUtteranceDefaultSpeechRate {
//            return
//        }
//        else if englishEnabled && utterance.voice == AVSpeechSynthesisVoice(language: Constants.LanguageCodes.PrimarySpeech) {
//            speakCurrentVerse(langCode: Constants.LanguageCodes.SecondarySpeech)
//        }
//        else {
//            currentSpokenVerseIndex += 1
//            if currentSpokenVerseIndex < speechVerses.count {
//                speakCurrentVerse(langCode: Constants.LanguageCodes.PrimarySpeech)
//            }
//            else {
//                currentSpokenVerseIndex = 0
//                speechPlayButton.setImage(#imageLiteral(resourceName: "Headset"), for: .normal)
//                hideSpeechSkipButtons()
//            }
//        }
//    }
//
//    func addRemoteControlEvent() {
//        let commandCenter = MPRemoteCommandCenter.shared()
//
//        commandCenter.playCommand.addTarget(self, action: #selector(speechPlayButtonTapped))
//        commandCenter.pauseCommand.addTarget(self, action: #selector(speechPlayButtonTapped))
//        commandCenter.nextTrackCommand.addTarget(self, action: #selector(speechForwardButtonTapped))
//        commandCenter.previousTrackCommand.addTarget(self, action: #selector(speechBackButtonTapped))
//    }
//
//    func registerForNotifications() {
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(handleInterruption),
//                                               name: .AVAudioSessionInterruption,
//                                               object: AVAudioSession.sharedInstance())
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(handleRouteChange),
//                                               name: .AVAudioSessionRouteChange,
//                                               object: AVAudioSession.sharedInstance())
//    }
//
//    @objc func handleInterruption(_ notification: Notification) {
//        guard let info = notification.userInfo,
//            let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
//            let type = AVAudioSessionInterruptionType(rawValue: typeValue) else {
//                return
//        }
//
//        switch type {
//        case .began:
//            pauseSpeaking()
//            break
//
//        case .ended:
//            pauseSpeaking()
//            break
//        }
//    }
//
//    @objc func handleRouteChange(_ notification: Notification) {
//        guard let info = notification.userInfo,
//            let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
//            let reason = AVAudioSessionRouteChangeReason(rawValue: reasonValue) else {
//                return
//        }
//
//        switch reason {
//        case .oldDeviceUnavailable:
//            pauseSpeaking()
//            break
//
//        default:
//            break
//        }
//    }
//
//    func startSpeaking() {
//        speechActive = true
//        speakCurrentVerse(langCode: Constants.LanguageCodes.PrimarySpeech)
//        speechPlayButton.setImage(#imageLiteral(resourceName: "Pause"), for: .normal)
//        showSpeechSkipButtons()
//    }
//
//    func pauseSpeaking() {
//        speechActive = false
//        speechSynthesizer.pauseSpeaking(at: AVSpeechBoundary.immediate)
//        DispatchQueue.main.async {
//            self.speechPlayButton.setImage(#imageLiteral(resourceName: "Headset"), for: .normal)
//            self.hideSpeechSkipButtons()
//        }
//    }
//
//    func continueSpeaking() {
//        speechActive = true
//        speechSynthesizer.continueSpeaking()
//        speechPlayButton.setImage(#imageLiteral(resourceName: "Pause"), for: .normal)
//        showSpeechSkipButtons()
//    }
//
//    func stopSpeaking() {
//        if PurchaseManager.shared.isPurchased {
//            speechActive = false
//            speechSynthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
//            speechPlayButton.setImage(#imageLiteral(resourceName: "Headset"), for: .normal)
//            hideSpeechSkipButtons()
//        }
//    }
//
//    func showSpeechSkipButtons() {
//        speechForwardButton.isHidden = false
//        speechBackButton.isHidden = false
//    }
//
//    func hideSpeechSkipButtons() {
//        speechForwardButton.isHidden = true
//        speechBackButton.isHidden = true
//    }
//}
