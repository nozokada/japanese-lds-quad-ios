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
    
    var scripturesToSpeak: Results<Scripture>!
    lazy var speechSynthesizer: AVSpeechSynthesizer = {
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.delegate = self
        return synthesizer
    }()
    var allowedToPlayNext = false
    var currentSpokenVerseIndex = 0
    var currentSpeechRate = AVSpeechUtteranceDefaultSpeechRate
    var currentUtterance: AVSpeechUtterance!
    var remainingSpeechText = ""
    
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
        scripturesToSpeak = scriptures.filter(
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
    
    func play(text: String = "", language: String = Constants.LanguageCode.primarySpeech, withNumber: Bool = false) {
        if !allowedToPlayNext { return }
        
        if text.isEmpty {
            speakCurrentVerse(language: language, withNumber: withNumber)
        } else {
            speak(text: text, language: language)
        }
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
    
    func speakCurrentVerse(language: String, withNumber: Bool) {
        guard let scriptures = scripturesToSpeak else { return }
        let scripture = scriptures[currentSpokenVerseIndex]
        
        var speechText = withNumber ? "\(scripture.verse): " : ""
        speechText.append(language == Constants.LanguageCode.primarySpeech
            ? SpeechUtility.correctPrimaryLanguage(speechText: scripture.scripture_primary_raw)
            : SpeechUtility.correctSecondaryLanguage(speechText: scripture.scripture_secondary_raw))
        
        speak(text: speechText, language: language)
    }
    
    func speak(text: String, language: String) {
        initUtterance(speechString: text, language: language)
        speechSynthesizer.speak(currentUtterance)
    }
    
    func initUtterance(speechString: String, language: String) {
        let newUtterance = AVSpeechUtterance(string: speechString)
        newUtterance.voice = AVSpeechSynthesisVoice(language: language)
        newUtterance.rate = currentSpeechRate
        currentUtterance = newUtterance
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
        if scripturesToSpeak == nil {
            delegate?.updateScripturesToSpeech()
        }
        allowedToPlayNext = true
        currentSpokenVerseIndex += 1
        if currentSpokenVerseIndex < scripturesToSpeak.count {
            stop()
            play(withNumber: true)
        } else {
            currentSpokenVerseIndex -= 1
        }
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        if scripturesToSpeak == nil {
             delegate?.updateScripturesToSpeech()
        }
        allowedToPlayNext = true
        stop()
        currentSpokenVerseIndex -= 1
        if currentSpokenVerseIndex < 0 {
            currentSpokenVerseIndex += 1
        }
        play(withNumber: true)
    }
    
    @IBAction func fasterButtonTapped(_ sender: Any) {
        guard let voice = currentUtterance.voice else { return }
        if speechSynthesizer.isSpeaking {
            currentSpeechRate += 0.05
            stop()
            play(text: remainingSpeechText, language: voice.language)
        }
    }
    
    @IBAction func slowerButton(_ sender: Any) {
        guard let voice = currentUtterance.voice else { return }
        if speechSynthesizer.isSpeaking {
            currentSpeechRate -= 0.05
            stop()
            play(text: remainingSpeechText, language: voice.language)
        }
    }
}

extension SpeechViewController: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if utterance.voice == AVSpeechSynthesisVoice(language: Constants.LanguageCode.primarySpeech)
            && AppUtility.shared.dualEnabled() {
            play(language: Constants.LanguageCode.secondarySpeech)
            return
        }
        
        currentSpokenVerseIndex += 1
        if currentSpokenVerseIndex < scripturesToSpeak.count {
            play()
        } else {
            stop()
            currentSpokenVerseIndex = 0
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        remainingSpeechText = String(utterance.speechString.dropFirst(characterRange.location))
        debugPrint(remainingSpeechText)
    }
}
