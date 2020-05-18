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
    
    var delegate: SpeechViewDelegate?

    @IBOutlet weak var playOrPauseButton: UIButton!
    @IBOutlet weak var fasterButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var slowerButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var speechRateLabel: UILabel!
    
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
    var spokenText = ""
    var remainingText = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setSpeechRateLabel(value: Utilities.shared.speechRateMultiplier)
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
    
    func initScripturesToSpeech(chapterId: String, scriptures: Results<Scripture>) {
        allowedToPlayNext = false
        stop()
        scripturesToSpeak = scriptures.filter(
            "id BEGINSWITH '\(chapterId)' AND NOT verse IN {'title', 'counter', 'preface', 'intro', 'summary', 'date'}"
        ).sorted(byKeyPath: "id")
        nextSpeechIndex = 0
    }
    
    func show(animated: Bool = true) {
        updateTopY()
        UIView.animate(withDuration: animated ? Constants.Rate.slideDurationInSec : 0) {
            let frame = self.view.frame
            let y = self.topY + self.playOrPauseButton.frame.height + Constants.Size.speechViewButtonVerticalPadding * 2
            self.view.frame = CGRect(x: 0, y: y, width: frame.width, height: frame.height)
        }
        isHidden = false
    }
    
    func hide(animated: Bool = true) {
        updateTopY()
        UIView.animate(withDuration: animated ? Constants.Rate.slideDurationInSec : 0) {
            let frame = self.view.frame
            let y = self.topY
            self.view.frame = CGRect(x: 0, y: y, width: frame.width, height: frame.height)
        }
        isHidden = true
    }
    
    fileprivate func setSpeechRateLabel(value: Float) {
        speechRateLabel.text = "\(String(format: "%.1f", value))x"
    }
    
    fileprivate func prepareBackgroundView() {
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(blurEffectView, at: 0)
    }
    
    fileprivate func updateImage(for button: UIButton, imageName: String) {
        let image = UIImage(named: imageName)
        button.setImage(image, for: .normal)
    }
    
    fileprivate func updateTopY() {
        topY = 0 - view.frame.height
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
    
    fileprivate func initUtterance(speechString: String, lang: String) {
        let newUtterance = AVSpeechUtterance(string: speechString)
        newUtterance.voice = AVSpeechSynthesisVoice(language: lang)
        newUtterance.rate = Utilities.shared.getSpeechRate()
        currentUtterance = newUtterance
    }
    
    fileprivate func play(text: String, in lang: String) {
        speak(text: text, in: lang)
        playOrPauseButton.setImage(UIImage(named: "Pause"), for: .normal)
    }
    
    fileprivate func playNext(withNumber: Bool = false, in lang: String = Constants.Lang.primarySpeech) {
        guard allowedToPlayNext else { return }
        guard let scriptures = scripturesToSpeak else { return }
        
        if nextSpeechIndex < 0 || nextSpeechIndex >= scripturesToSpeak.count {
            nextSpeechIndex = 0
        }
        let scripture = scriptures[nextSpeechIndex]
        let speechText = getScriptureSpeechText(scripture: scripture, withNumber: withNumber, in: lang)
        stop()
        speak(text: speechText, in: lang)
        nextSpeechIndex += 1
        updateImage(for: playOrPauseButton, imageName: "Pause")
    }
    
    fileprivate func pause() {
        speechSynthesizer.pauseSpeaking(at: .immediate)
        updateImage(for: playOrPauseButton, imageName: "Play")
    }
    
    fileprivate func resume() {
        speechSynthesizer.continueSpeaking()
        updateImage(for: playOrPauseButton, imageName: "Pause")
    }
    
    fileprivate func stop() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        updateImage(for: playOrPauseButton, imageName: "Play")
    }
    
    fileprivate func getScriptureSpeechText(scripture: Scripture, withNumber: Bool, in lang: String) -> String {
        var speechText = withNumber ? "\(scripture.verse): " : ""
        speechText.append(lang == Constants.Lang.primarySpeech
            ? SpeechUtilities.correctPrimaryLang(speechText: scripture.scripture_primary_raw)
            : SpeechUtilities.correctSecondaryLang(speechText: scripture.scripture_secondary_raw))
        
        return speechText
    }
    
    fileprivate func speak(text: String, in lang: String) {
        initUtterance(speechString: text, lang: lang)
        speechSynthesizer.speak(currentUtterance)
    }
    
    fileprivate func changeSpeechRateMultiplier(by value: Float) {
        let newValue = Utilities.shared.speechRateMultiplier + value
        if newValue < Constants.Rate.speechRateMinimumMultiplier
            || newValue > Constants.Rate.speechRateMaximumMultiplier {
            return
        }
        UserDefaults.standard.set(newValue, forKey: Constants.Config.rate)
        setSpeechRateLabel(value: newValue)
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
        guard let utterance = currentUtterance else { return }
        
        changeSpeechRateMultiplier(by: Constants.Rate.speechRateMultiplierStep)
        if remainingText.isEmpty { return }
        stop()
        play(text: remainingText, in: utterance.voice!.language)
    }
    
    @IBAction func slowerButton(_ sender: Any) {
        guard let utterance = currentUtterance else { return }

        changeSpeechRateMultiplier(by: -Constants.Rate.speechRateMultiplierStep)
        if remainingText.isEmpty { return }
        stop()
        play(text: remainingText, in: utterance.voice!.language)
    }
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        if scripturesToSpeak == nil {
            delegate?.updateScripturesToSpeech()
        }
        allowedToPlayNext = true
        playNext(withNumber: true)
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        guard let utterance = currentUtterance else { return }
        
        if scripturesToSpeak == nil {
            delegate?.updateScripturesToSpeech()
        }
        allowedToPlayNext = true
        
        nextSpeechIndex -= 1
        if utterance.speakingPrimary && spokenText.count < 8 {
            nextSpeechIndex -= 1
        }
        playNext(withNumber: true)
    }
}

extension SpeechViewController: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        remainingText = ""
        
        if utterance.speakingPrimary && Utilities.shared.dualEnabled {
            nextSpeechIndex -= 1
            playNext(in: Constants.Lang.secondarySpeech)
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
    }
}
