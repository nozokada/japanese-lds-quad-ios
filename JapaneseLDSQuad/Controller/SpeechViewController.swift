//
//  SpeechViewController.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/24/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit
import RealmSwift
import AVFoundation

class SpeechViewController: UIViewController {
    
    var delegate: ScriptureToSpeechDelegate?

    @IBOutlet weak var playOrPauseButton: UIButton!
    @IBOutlet weak var fasterButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var slowerButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    var speechVerses: Results<Scripture>!
    lazy var speechSynthesizer: AVSpeechSynthesizer = {
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.delegate = self
        return synthesizer
    }()
    var currentSpokenVerseIndex = 0
    
    var topY: CGFloat = 0
    var isHidden = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reload()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        view.isHidden = true
        coordinator.animate(alongsideTransition: nil) { _ in
            if self.isHidden {
                self.hide(animated: false)
            } else {
                self.show(animated: false)
            }
            self.view.isHidden = false
        }
    }
    
    func initScriptureToSpeech(chapterId: String, scriptures: Results<Scripture>) {
        speechVerses = scriptures.filter(
            "id BEGINSWITH '\(chapterId)' AND NOT verse IN {'title', 'counter', 'preface', 'intro', 'summary', 'date'}"
        ).sorted(byKeyPath: "id")
    }
    
    func updateTopY() {
        topY = 0 - view.frame.height
    }
    
    func show(animated: Bool = true) {
        updateTopY()
        UIView.animate(withDuration: animated ? Constants.Duration.slideUpViewAnimation : 0) {
            let frame = self.view.frame
            let y = self.topY + self.playOrPauseButton.frame.height + Constants.Size.speechViewButtonVerticalPadding * 2
            self.view.frame = CGRect(x: 0, y: y, width: frame.width, height: frame.height)
        }
        isHidden = false
    }
    
    func hide(animated: Bool = true) {
        updateTopY()
        UIView.animate(withDuration: animated ? Constants.Duration.slideUpViewAnimation : 0) {
            let frame = self.view.frame
            let y = self.topY
            self.view.frame = CGRect(x: 0, y: y, width: frame.width, height: frame.height)
        }
        isHidden = true
    }
}

extension SpeechViewController: SettingsChangeDelegate {
    
    func reload() {
        view.backgroundColor = AppUtility.shared.getCurrentBackgroundColor()
    }
}

extension SpeechViewController: AVSpeechSynthesizerDelegate {
    
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
