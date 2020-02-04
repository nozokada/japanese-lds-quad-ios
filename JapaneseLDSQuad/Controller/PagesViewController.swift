//
//  PagesViewController.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/3/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit
import RealmSwift

class PagesViewController: UIPageViewController {

    var scripturesList: Results<Scripture>!
        
    var targetBookName = ""
    var targetBook: Book!
    var targetVerse = ""
    var targetChapterId = ""
    var targetScriptureId = ""
    
    var currentContentViewController: ContentViewController!
    var currentChapterIndex: Int!
    var webViewRelativeOffset: CGFloat = 0
    
    var contentType = (gs: false, hymn: false, scripture: true)
    
//    var speechVerses: Results<Scripture>!
//    var currentSpokenVerseIndex = 0
//    var speechActive = false
//    let speechQueue = DispatchQueue(label: "com.nozokada.JapaneseLDSQuad.speechQueue")
//    let speechSynthesizer = AVSpeechSynthesizer()
    
//    @IBOutlet weak var dualSwitch: UIBarButtonItem!
//    @IBOutlet weak var passageLookUpViewButton: UIBarButtonItem!
//    @IBOutlet weak var highlightsViewButton: UIBarButtonItem!
//    var speechPlayButton: UIButton!
//    var speechForwardButton: UIButton!
//    var speechBackButton: UIButton!
//
//    let speechButtonSize: CGFloat = 50
//    let speechButtonOffset: CGFloat = -20
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        self.dataSource = self
        
        contentType.gs = targetBook.link.hasPrefix("gs")
        contentType.hymn = targetBook.link.hasPrefix("hymns")
        contentType.scripture = !(contentType.gs || contentType.hymn || targetBook.link.hasSuffix("_cont"))
        
        scripturesList = targetBook.child_scriptures.sorted(byKeyPath: "id")
        if let counter = scripturesList.filter("verse = 'counter' AND id BEGINSWITH '\(targetChapterId)'").first?.scripture_primary {
            if counter.isEmpty {
                self.title = contentType.gs ?
                    scripturesList.filter("verse = 'title' AND id BEGINSWITH '\(targetChapterId)'").first?.scripture_primary.replacingOccurrences(of: Constants.RegexPattern.tags, with: "", options: .regularExpression) :
                    scripturesList.first?.parent_book.name_primary
            } else {
                self.title = "\(targetBookName) \(counter)"
            }
        }
        currentChapterIndex = DataService.shared.getChapterNumber(id: targetChapterId) - 1
        currentContentViewController = getViewControllerAtIndex(index: currentChapterIndex)
        
//        speechSynthesizer.delegate = self
//        initializeSpeechButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        updateDualSwitch()
        updatePageContentView()
//        updateAdditionalFeatureBarButtons()
//        initializeSpeechButtons()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        clearTargetScripture()
        saveCurrentRelativeOffset()
//        stopSpeaking()
    }
    
    func saveCurrentRelativeOffset() {
        let offset = currentContentViewController.webView.scrollView.contentOffset.y
        let height = currentContentViewController.webView.scrollView.contentSize.height
        
        webViewRelativeOffset = offset / height
    }
    
    func updatePageContentView() {
        self.setViewControllers([getViewControllerAtIndex(index: currentChapterIndex)] as [UIViewController], direction: UIPageViewController.NavigationDirection.forward, animated: false, completion: nil)
        
        currentContentViewController = viewControllers?.last as! ContentViewController?
        currentContentViewController.relativeOffset = webViewRelativeOffset
    }
    
    func clearTargetScripture() {
        targetVerse = ""
        targetScriptureId = ""
    }
    
//    @IBAction func rootButtonTapped(_ sender: Any) {
//        let currentNavigationController = self.navigationController as! AppNavigationController
//
//        if let previousNavigationController = currentNavigationController.previousNavigationController {
//            currentNavigationController.dismiss(animated: true, completion: nil)
//            previousNavigationController.popToRootViewController(animated: true)
//        }
//        else {
//            currentNavigationController.popToRootViewController(animated: true)
//        }
//    }
    
//    @IBAction func passageLookupViewButtonTapped(_ sender: Any) {
//        let navigationController = self.navigationController as! AppNavigationController
//
//        if navigationController.isPassageLookupNavigationController {
//            navigationController.popToRootViewController(animated: true)
//        }
//        else {
//            presentPassageLookupViewController()
//        }
//    }
//
//    @IBAction func searchButtonTapped(_ sender: Any) {
//        let navigationController = self.navigationController as! AppNavigationController
//
//        if navigationController.isSearchNavigationController {
//            navigationController.popToRootViewController(animated: true)
//        }
//        else {
//            presentSearchViewController()
//        }
//    }
//
//    @IBAction func highlightsButtonTapped(_ sender: Any) {
//        presentHighlightsViewController()
//    }
//
//    @IBAction func bookmarksButtonTapped(_ sender: Any) {
//        presentBookmarksViewController()
//    }
//
//    @IBAction func settingsButtonTapped(_ sender: UIBarButtonItem) {
//        presentSettingsTableViewController(sender)
//    }
//
//    @IBAction func dualSwitchToggled(_ sender: Any) {
//        changeDualMode()
//    }
//
//    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
//        return UIModalPresentationStyle.none
//    }
    
//    func initializeSpeechButtons() {
//        if PurchaseManager.shared.isPurchased {
//            speechPlayButton = createSpeechButton(iconImage: #imageLiteral(resourceName: "Headset"), horizontalOffset: 0)
//            speechForwardButton = createSpeechButton(iconImage: #imageLiteral(resourceName: "Skip"), horizontalOffset: -60)
//            speechBackButton = createSpeechButton(iconImage: #imageLiteral(resourceName: "Back"), horizontalOffset: -120)
//
//            speechPlayButton.addTarget(self, action: #selector(speechPlayButtonTapped), for: .touchUpInside)
//            speechForwardButton.addTarget(self, action: #selector(speechForwardButtonTapped), for: .touchUpInside)
//            speechBackButton.addTarget(self, action: #selector(speechBackButtonTapped), for: .touchUpInside)
//
//            // addRemoteControlEvent()
//            registerForNotifications()
//            loadSpeechVerses()
//            hideSpeechSkipButtons()
//        }
//    }
    
//    func createSpeechButton(iconImage: UIImage, horizontalOffset: CGFloat) -> UIButton {
//        let button = UIButton(frame: CGRect(x: 0, y: 0, width: speechButtonSize, height: speechButtonSize))
//        let imageEdgeInset = speechButtonSize * 0.2
//        button.setImage(iconImage, for: .normal)
//        button.imageEdgeInsets = UIEdgeInsetsMake(imageEdgeInset + 2, imageEdgeInset, imageEdgeInset, imageEdgeInset);
//        button.backgroundColor = UIColor.orange
//        button.layer.cornerRadius = 0.5 * button.bounds.size.width
//        button.clipsToBounds = true
//        button.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(button)
//
//        let buttonRightConstraint = NSLayoutConstraint(
//            item: button,
//            attribute: NSLayoutAttribute.trailing,
//            relatedBy: NSLayoutRelation.equal,
//            toItem: self.view,
//            attribute: NSLayoutAttribute.trailing,
//            multiplier: 1.0,
//            constant: speechButtonOffset + horizontalOffset
//        )
//
//        let buttonBottomConstraint = NSLayoutConstraint(
//            item: button,
//            attribute: NSLayoutAttribute.bottom,
//            relatedBy: NSLayoutRelation.equal,
//            toItem: self.view,
//            attribute: NSLayoutAttribute.bottom,
//            multiplier: 1.0,
//            constant: speechButtonOffset
//        )
//        self.view.addConstraints([buttonRightConstraint, buttonBottomConstraint])
//
//        return button
//    }
}


//extension ContentViewController: UpperBarButtonsDelegate {
//
//    func reload() {
//        clearTargetScripture()
//        updateDualSwitch()
//        updateAdditionalFeatureBarButtons()
//        saveCurrentRelativeOffset()
//        updatePageContentView()
//    }
//}

extension PagesViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let currentViewController = viewController as? ContentViewController {
            let currentIndex = currentViewController.pageIndex
            return currentIndex > 0 ? getViewControllerAtIndex(index: currentIndex - 1) : nil
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let currentViewController = viewController as? ContentViewController {
            let currentIndex = currentViewController.pageIndex
            let lastChapter = DataService.shared.getChapterNumber(id: (scripturesList.last?.id)!)
            return currentIndex < lastChapter - 1 ? getViewControllerAtIndex(index: currentIndex + 1) : nil
        }
        return nil
    }
    
    func getViewControllerAtIndex(index: Int) -> ContentViewController {
        let chapter = index + 1
        let chapterId = DataService.shared.getChapterId(bookId: targetBook.id, chapter: chapter)
        let scriptures = scripturesList.filter("id BEGINSWITH '\(chapterId)'").sorted(byKeyPath: "id")
        let contentBuilder = ContentBuilder(scriptures: scriptures, targetVerse: targetVerse)
        
        let contentViewController = storyboard?.instantiateViewController(withIdentifier: "pageContent") as! ContentViewController
        contentViewController.pageIndex = index
        contentViewController.pageContents = contentBuilder.build(type: contentType)
        contentViewController.targetBook = targetBook
        contentViewController.targetChapterId = targetChapterId
        
        if chapterId == targetChapterId { contentViewController.targetVerse = targetVerse }
        contentViewController.targetScriptureId = targetScriptureId
        
        return contentViewController
    }
}

extension PagesViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if finished && completed {
            currentContentViewController = pageViewController.viewControllers?[0] as! ContentViewController?
            currentChapterIndex = currentContentViewController.pageIndex
            targetChapterId = DataService.shared.getChapterId(bookId: targetBook.id, chapter: currentChapterIndex + 1)
            
            if contentType.gs {
                self.title = scripturesList.filter("verse = 'title' AND id BEGINSWITH '\(targetChapterId)'").first?.scripture_primary.replacingOccurrences(of: Constants.RegexPattern.tags, with: "", options: .regularExpression)
            }
            else {
                let counter = scripturesList.filter("verse = 'counter' AND id BEGINSWITH '\(targetChapterId)'").first?.scripture_primary
                self.title = targetBookName + " " + counter!
            }
        }
        clearTargetScripture()
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
