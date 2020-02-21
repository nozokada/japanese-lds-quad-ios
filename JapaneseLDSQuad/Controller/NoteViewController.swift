//
//  NoteViewController.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/19/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit
import RealmSwift

protocol HighlightChangeDelegate {
    
    func removeHighlight(id: String)
}

class NoteViewController: UIViewController {
    
    var realm: Realm!
    
    var delegate: HighlightChangeDelegate?
    
    @IBOutlet weak var noteViewTitleLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var noteTextView: UITextView!
    @IBOutlet weak var noteTextViewHeight: NSLayoutConstraint!
    @IBOutlet weak var saveButton: MainButton!
    
    var highlightedText: HighlightedText?
    var bottomY: CGFloat = UIScreen.main.bounds.height
    
    let noteTextViewPlaceholder = "notePlaceholder".localized
    let noteTextViewPlaceholderTextColor = UIColor.lightGray

    override func viewDidLoad() {
        super.viewDidLoad()
        realm = try! Realm()
        noteTextView.delegate = self
        saveButton.setTitle("noteSaveButton".localized, for: .normal)
        adjustNoteTextViewHeight()
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(panGesture))
        view.addGestureRecognizer(gesture)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reload()
    }
    
    func initHighlightedText(id: String) {
        if let highlightedText = realm.objects(HighlightedText.self).filter("id = '\(id)'").first {
            self.highlightedText = highlightedText
        }
        reload()
    }
    
    func setTitleAndNote() {
        noteViewTitleLabel.text = Locale.current.languageCode == Constants.LanguageCode.primary
            ? highlightedText?.name_primary
            : highlightedText?.name_secondary
        noteTextView.text = highlightedText?.note
        
        if noteTextView.text.isEmpty {
            noteTextView.text = noteTextViewPlaceholder
            noteTextView.textColor = noteTextViewPlaceholderTextColor
        } else {
            noteTextView.textColor = AppUtility.shared.getCurrentTextColor()
        }
    }
    
    func adjustNoteTextViewHeight() {
        noteTextViewHeight.constant = view.frame.height / 3
            - noteViewTitleLabel.frame.height
            - Constants.Size.noteViewTitleVerticalPadding * 2
    }
    
    func show() {
        if let superview = view.superview {
            bottomY = superview.frame.maxY
        }
        UIView.animate(withDuration: Constants.Duration.noteViewAnimation) {
            let frame = self.view.frame
            let y = self.bottomY - frame.height / 3
            self.view.frame = CGRect(x: 0, y: y, width: frame.width, height: frame.height)
        }
    }
    
    func showFull() {
        UIView.animate(withDuration: Constants.Duration.noteViewAnimation) {
            let frame = self.view.frame
            let y = self.bottomY - frame.height / 2
            self.view.frame = CGRect(x: 0, y: y, width: frame.width, height: frame.height)
        }
    }
    
    func hide() {
        UIView.animate(withDuration: Constants.Duration.noteViewAnimation) {
            let frame = self.view.frame
            let y = self.bottomY
            self.view.frame = CGRect(x: 0, y: y, width: frame.width, height: frame.height)
        }
    }
    
    @objc func panGesture(recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: view)
        let frame = view.frame
        let newY = frame.minY + translation.y
        if newY > bottomY - frame.height {
            view.frame = CGRect(x: 0, y: newY, width: frame.width, height: frame.height)
            recognizer.setTranslation(CGPoint.zero, in: view)
        }
        
        if recognizer.state == .ended {
            if newY < bottomY - frame.height / 2 {
                showFull()
            } else if newY >= bottomY - frame.height / 2 && newY < bottomY - frame.height / 2.5 {
                showFull()
            } else if newY >= bottomY - frame.height / 2.5 && newY < bottomY - frame.height / 3 {
                show()
            } else if newY >= bottomY - frame.height / 3 && newY < bottomY - frame.height / 3.5 {
                show()
            } else {
                hide()
            }
        }
    }
    
    @IBAction func deleteButtonTapped(_ sender: Any) {
        guard let highlightedText = highlightedText else { return }
        delegate?.removeHighlight(id: highlightedText.id)
    }
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        var textToSave = ""
        if noteTextView.textColor != noteTextViewPlaceholderTextColor {
            textToSave = noteTextView.text
        }
        try! realm.write {
            highlightedText?.note = textToSave
        }
        saveButton.disable()
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        hide()
    }
}

extension NoteViewController: SettingsChangeDelegate {
    
    func reload() {
        setTitleAndNote()
        saveButton.disable()
        noteTextView.backgroundColor = AppUtility.shared.getCurrentBackgroundColor()
        view.backgroundColor = noteTextView.backgroundColor
    }
}

extension NoteViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        showFull()
        
        if textView.textColor == noteTextViewPlaceholderTextColor {
            textView.text = nil
            textView.textColor = AppUtility.shared.getCurrentTextColor()
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = noteTextViewPlaceholder
            textView.textColor = noteTextViewPlaceholderTextColor
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        saveButton.enable()
    }
}
