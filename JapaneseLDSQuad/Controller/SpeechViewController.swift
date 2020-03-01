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
    
    var topY: CGFloat = 0
    var isHidden = true
    
    var scripturesToSpeak: Results<Scripture>!
    lazy var speechSynthesizer: AVSpeechSynthesizer = {
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.delegate = self
        return synthesizer
    }()
    var allowedToPlayNext = false
    var nextSpeechIndex = 0
    var currentUtterance: AVSpeechUtterance!
    var currentSpeechRate = AVSpeechUtteranceDefaultSpeechRate
    var spokenText = ""
    var remainingText = ""
    
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
    
    func updateTopY() {
        topY = 0 - view.frame.height
    }
    
    func show(animated: Bool = true) {
        updateTopY()
        UIView.animate(withDuration: animated ? Constants.Duration.slideViewAnimation : 0) {
            let frame = self.view.frame
            let y = self.topY + self.playOrPauseButton.frame.height + Constants.Size.speechViewButtonVerticalPadding * 2
            self.view.frame = CGRect(x: 0, y: y, width: frame.width, height: frame.height)
        }
        isHidden = false
    }
    
    func hide(animated: Bool = true) {
        updateTopY()
        UIView.animate(withDuration: animated ? Constants.Duration.slideViewAnimation : 0) {
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
    
    func initScripturesToSpeech(chapterId: String, scriptures: Results<Scripture>) {
        allowedToPlayNext = false
        stop()
        scripturesToSpeak = scriptures.filter(
            "id BEGINSWITH '\(chapterId)' AND NOT verse IN {'title', 'counter', 'preface', 'intro', 'summary', 'date'}"
        ).sorted(byKeyPath: "id")
        nextSpeechIndex = 0
    }
    
    func initUtterance(speechString: String, language: String) {
        let newUtterance = AVSpeechUtterance(string: speechString)
        newUtterance.voice = AVSpeechSynthesisVoice(language: language)
        newUtterance.rate = currentSpeechRate
        currentUtterance = newUtterance
    }
    
    func play(text: String, in language: String) {
        speak(text: text, in: language)
        playOrPauseButton.setImage(UIImage(systemName: "pause"), for: .normal)
    }
    
    func playNext(withNumber: Bool = false, in language: String = Constants.Language.primarySpeech) {
        guard allowedToPlayNext else { return }
        guard let scriptures = scripturesToSpeak else { return }
        
        if nextSpeechIndex < 0 || nextSpeechIndex >= scripturesToSpeak.count {
            nextSpeechIndex = 0
        }
        let scripture = scriptures[nextSpeechIndex]
        let speechText = getScriptureSpeechText(scripture: scripture, withNumber: withNumber, in: language)
        stop()
        speak(text: speechText, in: language)
        nextSpeechIndex += 1
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
    
    func getScriptureSpeechText(scripture: Scripture, withNumber: Bool, in language: String) -> String {
        var speechText = withNumber ? "\(scripture.verse): " : ""
        speechText.append(language == Constants.Language.primarySpeech
            ? SpeechUtility.correctPrimaryLanguage(speechText: scripture.scripture_primary_raw)
            : SpeechUtility.correctSecondaryLanguage(speechText: scripture.scripture_secondary_raw))
        
        return speechText
    }
    
    func speak(text: String, in language: String) {
        initUtterance(speechString: text, language: language)
        speechSynthesizer.speak(currentUtterance)
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
            playNext()
        }
    }
    
    @IBAction func fasterButtonTapped(_ sender: Any) {
        guard let utterance = currentUtterance,
            let voice = utterance.voice else { return }
        
        currentSpeechRate += 0.0625
        if remainingText.isEmpty { return }
        stop()
        play(text: remainingText, in: voice.language)
    }
    
    @IBAction func slowerButton(_ sender: Any) {
        guard let utterance = currentUtterance,
            let voice = utterance.voice else { return }
        
        currentSpeechRate -= 0.0625
        if remainingText.isEmpty { return }
        stop()
        play(text: remainingText, in: voice.language)
    }
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        if scripturesToSpeak == nil {
            delegate?.updateScripturesToSpeech()
        }
        allowedToPlayNext = true
        playNext(withNumber: true)
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        if scripturesToSpeak == nil {
            delegate?.updateScripturesToSpeech()
        }
        allowedToPlayNext = true
        
        nextSpeechIndex -= 1
        if currentUtterance.speakingPrimary && spokenText.count < 5 {
            nextSpeechIndex -= 1
        }
        playNext(withNumber: true)
    }
}

extension SpeechViewController: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        remainingText = ""
        
        if utterance.speakingPrimary && AppUtility.shared.dualEnabled {
            nextSpeechIndex -= 1
            playNext(in: Constants.Language.secondarySpeech)
            return
        }
        
        if nextSpeechIndex < scripturesToSpeak.count {
            playNext()
        } else {
            stop()
            nextSpeechIndex = 0
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        remainingText = String(utterance.speechString.dropFirst(characterRange.location))
        spokenText = String(utterance.speechString.prefix(characterRange.location))
//        debugPrint("Spoken: \(spokenText)")
//        debugPrint("Reamining: \(remainingText)")
    }
}

extension AVSpeechUtterance {
    
    var speakingPrimary: Bool {
        return voice?.language == Constants.Language.primarySpeech
    }
    
    var speakingSecondary: Bool {
        return voice?.language == Constants.Language.secondarySpeech
    }
}
