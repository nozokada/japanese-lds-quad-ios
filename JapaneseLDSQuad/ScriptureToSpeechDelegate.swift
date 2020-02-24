//
//  TextToSpeechDelegate.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/22/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import Foundation
import RealmSwift
import AVFoundation

protocol ScriptureToSpeechDelegate {
    
    var speechSynthesizer: AVSpeechSynthesizer { get set }
    var speechVerses: Results<Scripture>? { get }
//    var speechQueue: DispatchQueue { get }
    var currentSpokenVerseIndex: Int { get set }
}

extension ScriptureToSpeechDelegate where Self: UIViewController {
    
    func setSpeechBarButton() {
        let speechButton = UIBarButtonItem(image: UIImage(systemName: "headphones"), style: .plain, target: self, action: #selector(PagesViewController.showSpeechControlPanel(sender:)))
        if let barButtonItems = navigationItem.rightBarButtonItems {
            navigationItem.rightBarButtonItems = barButtonItems + [speechButton]
        } else {
            navigationItem.rightBarButtonItem = speechButton
        }
    }
}

extension PagesViewController: ScriptureToSpeechDelegate {
    
    var speechVerses: Results<Scripture>? {
        get {
            guard let chapterId = targetChapterId else { return nil }
            return scripturesInBook.filter(
                "id BEGINSWITH '\(chapterId)' AND NOT verse IN {'title', 'counter', 'preface', 'intro', 'summary', 'date'}"
            ).sorted(byKeyPath: "id")
        }
    }
    
    @objc func showSpeechControlPanel(sender: UIBarButtonItem) {
        debugPrint(speechVerses!)
        speakCurrentVerse(langCode: Constants.LanguageCode.primarySpeech)
    }
    
    func speakCurrentVerse(langCode: String) {
        guard let spokenVerse = speechVerses?[currentSpokenVerseIndex] else { return }
        let speechText = langCode == Constants.LanguageCode.primarySpeech
            ? SpeechUtility.correctPrimaryLanguage(speechText: spokenVerse.scripture_primary_raw)
            : SpeechUtility.correctSecondaryLanguage(speechText: spokenVerse.scripture_secondary_raw)

        DispatchQueue.main.async {
            let utterance = AVSpeechUtterance(string: speechText)
            utterance.voice = AVSpeechSynthesisVoice(language: langCode)
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
            self.speechSynthesizer.speak(utterance)
        }
    }
}

extension PagesViewController: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let englishEnabled = UserDefaults.standard.bool(forKey: Constants.Config.dual)
        if utterance.rate != AVSpeechUtteranceDefaultSpeechRate {
            return
        }
        else if englishEnabled && utterance.voice == AVSpeechSynthesisVoice(language: Constants.LanguageCode.primarySpeech) {
            speakCurrentVerse(langCode: Constants.LanguageCode.secondarySpeech)
        }
        else {
            currentSpokenVerseIndex += 1
            if currentSpokenVerseIndex < speechVerses!.count {
                speakCurrentVerse(langCode: Constants.LanguageCode.primarySpeech)
            }
            else {
                currentSpokenVerseIndex = 0
//                speechPlayButton.setImage(#imageLiteral(resourceName: "Headset"), for: .normal)
//                hideSpeechSkipButtons()
            }
        }
    }
}
