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
    
    var delegate: ScripturesToSpeechDelegate?

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
    var allowedToPlayNext = false
    var currentSpokenVerseIndex = 0
    
    var topY: CGFloat = 0
    var isHidden = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareBackgroundView()
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(panGesture))
        view.addGestureRecognizer(gesture)
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
    
    func prepareBackgroundView(){
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(blurEffectView, at: 0)
    }
    
    func initScripturesToSpeech(chapterId: String, scriptures: Results<Scripture>) {
        allowedToPlayNext = false
        stop()
        speechVerses = scriptures.filter(
            "id BEGINSWITH '\(chapterId)' AND NOT verse IN {'title', 'counter', 'preface', 'intro', 'summary', 'date'}"
        ).sorted(byKeyPath: "id")
        currentSpokenVerseIndex = 0
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
    
    @objc func panGesture(recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: view)
        let frame = view.frame
        let newY = frame.minY + translation.y
        if newY < 0 {
            view.frame = CGRect(x: 0, y: newY, width: frame.width, height: frame.height)
            recognizer.setTranslation(CGPoint.zero, in: view)
        }
        
        if recognizer.state == .ended {
            if newY > topY + playOrPauseButton.frame.height {
                show()
            } else {
                hide()
            }
        }
    }
    
    func play(langCode: String = Constants.LanguageCode.primarySpeech) {
        if !allowedToPlayNext { return }
        speakCurrentVerse(langCode: langCode)
        playOrPauseButton.setImage(UIImage(systemName: "pause"), for: .normal)
    }
    
    func pause() {
        speechSynthesizer.pauseSpeaking(at: .immediate)
        playOrPauseButton.setImage(UIImage(systemName: "play"), for: .normal)
    }
    
    func resume() {
        speechSynthesizer.continueSpeaking()
        playOrPauseButton.setImage(UIImage(systemName: "pause"), for: .normal)
    }
    
    func stop() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        playOrPauseButton.setImage(UIImage(systemName: "play"), for: .normal)
    }
    
    func speakCurrentVerse(langCode: String) {
        guard let verses = speechVerses else { return }
        let verse = verses[currentSpokenVerseIndex]
        let speechText = langCode == Constants.LanguageCode.primarySpeech
            ? SpeechUtility.correctPrimaryLanguage(speechText: verse.scripture_primary_raw)
            : SpeechUtility.correctSecondaryLanguage(speechText: verse.scripture_secondary_raw)

        let utterance = AVSpeechUtterance(string: speechText)
        utterance.voice = AVSpeechSynthesisVoice(language: langCode)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        speechSynthesizer.speak(utterance)
    }
    
    func speakCurrentVerseNumber() {
        let verseNumber = speechVerses[currentSpokenVerseIndex].verse
        let utterance = AVSpeechUtterance(string: "\(verseNumber)")
        utterance.voice = AVSpeechSynthesisVoice(language: Constants.LanguageCode.primarySpeech)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 1.1
        speechSynthesizer.speak(utterance)
    }
    
    @IBAction func playButtonTapped(_ sender: Any) {
        if speechSynthesizer.isPaused {
            allowedToPlayNext = true
            resume()
        } else if speechSynthesizer.isSpeaking {
            allowedToPlayNext = false
            pause()
        } else {
            delegate?.updateScripturesToSpeech()
            allowedToPlayNext = true
            play()
        }
    }
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        if speechVerses == nil {
            delegate?.updateScripturesToSpeech()
        }
        allowedToPlayNext = true
        currentSpokenVerseIndex += 1
        if currentSpokenVerseIndex < speechVerses.count {
            stop()
            speakCurrentVerseNumber()
            play()
        } else {
            currentSpokenVerseIndex -= 1
        }
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        if speechVerses == nil {
             delegate?.updateScripturesToSpeech()
        }
        allowedToPlayNext = true
        stop()
        currentSpokenVerseIndex -= 1
        if currentSpokenVerseIndex < 0 {
            currentSpokenVerseIndex += 1
        }
        speakCurrentVerseNumber()
        play()
    }
}

extension SpeechViewController: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let dualEnabled = UserDefaults.standard.bool(forKey: Constants.Config.dual)
        if utterance.rate != AVSpeechUtteranceDefaultSpeechRate {
            return
        } else if dualEnabled && utterance.voice == AVSpeechSynthesisVoice(language: Constants.LanguageCode.primarySpeech) {
            play(langCode: Constants.LanguageCode.secondarySpeech)
        } else {
            currentSpokenVerseIndex += 1
            if currentSpokenVerseIndex < speechVerses.count {
                play()
            } else {
                currentSpokenVerseIndex = 0
            }
        }
    }
}
