//
//  NoteViewController.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/19/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit

class NoteViewController: UIViewController {
        
    @IBOutlet weak var noteViewTitleLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var noteTextView: UITextView!
    @IBOutlet weak var noteTextViewHeight: NSLayoutConstraint!
    @IBOutlet weak var saveButton: MainButton!
    
    var highlightedTextId: String?
    var parentContentViewController: ContentViewController?
    var isHidden = true
    var bottomY: CGFloat = UIScreen.main.bounds.height
    let noteTextViewPlaceholder = "notePlaceholder".localized
    let noteTextViewPlaceholderTextColor = UIColor.lightGray

    override func viewDidLoad() {
        super.viewDidLoad()
        noteTextView.delegate = self
        saveButton.setTitle("noteSavedButtonLabel".localized, for: .normal)
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(panGesture))
        view.addGestureRecognizer(gesture)
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
    
    func setContentViewController(_ viewController: ContentViewController) {
        parentContentViewController = viewController
    }
    
    func initHighlightedText(id: String) {
        highlightedTextId = id
        reload()
        saveButton.disable()
        saveButton.hideSpinner()
    }
    
    func show(animated: Bool = true) {
        updateBottomY()
        adjustNoteTextViewHeight()
        
        UIView.animate(withDuration: animated ? Constants.Rate.slideDurationInSec : 0) {
            let frame = self.view.frame
            let y = self.bottomY - frame.height / 3
            self.view.frame = CGRect(x: 0, y: y, width: frame.width, height: frame.height)
        }
        isHidden = false
    }
    
    func showFull(animated: Bool = true) {
        updateBottomY()
        adjustNoteTextViewHeight()
        
        UIView.animate(withDuration: animated ? Constants.Rate.slideDurationInSec : 0) {
            let frame = self.view.frame
            let y = self.bottomY - frame.height / 2
            self.view.frame = CGRect(x: 0, y: y, width: frame.width, height: frame.height)
        }
        isHidden = false
    }
    
    func hide(animated: Bool = true) {
        updateBottomY()
        adjustNoteTextViewHeight()
        
        UIView.animate(withDuration: animated ? Constants.Rate.slideDurationInSec : 0) {
            let frame = self.view.frame
            let y = self.bottomY
            self.view.frame = CGRect(x: 0, y: y, width: frame.width, height: frame.height)
        }
        isHidden = true
    }
    
    fileprivate func setTitleAndNote() {
        guard let textId = highlightedTextId,
            let text = HighlightsManager.shared.get(textId: textId) else {
            return
        }
        noteViewTitleLabel.text = Utilities.shared.getSystemLang() == Constants.Lang.primary
            ? text.name_primary
            : text.name_secondary
        noteViewTitleLabel.sizeToFit()
        
        noteTextView.text = text.note
        if noteTextView.text.isEmpty {
            noteTextView.text = noteTextViewPlaceholder
            noteTextView.textColor = noteTextViewPlaceholderTextColor
        } else {
            noteTextView.textColor = Utilities.shared.getTextColor()
        }
    }
    
    fileprivate func adjustNoteTextViewHeight() {
        noteTextViewHeight.constant = view.frame.height / 3
            - noteViewTitleLabel.frame.height
            - Constants.Size.noteViewTitleVerticalPadding * 2
    }
    
    fileprivate func updateBottomY() {
        if let superview = view.superview {
            bottomY = superview.frame.maxY
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
        guard let textId = highlightedTextId,
            let text = HighlightsManager.shared.get(textId: textId) else {
            return
        }
        parentContentViewController?.removeHighlight(id: text.id)
    }
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        guard let textId = highlightedTextId,
            let text = HighlightsManager.shared.get(textId: textId) else {
            return
        }
        var textToSave = ""
        if noteTextView.textColor != noteTextViewPlaceholderTextColor {
            textToSave = noteTextView.text
        }
        HighlightsManager.shared.update(textId: text.id, note: textToSave)
        saveButton.disable()
        saveButton.hideSpinner()
        saveButton.setTitle("noteSavedButtonLabel".localized, for: .normal)
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        hide()
    }
}

extension NoteViewController: SettingsViewDelegate {
    
    func reload() {
        guard let textId = highlightedTextId,
            HighlightsManager.shared.get(textId: textId) != nil else {
                hide()
            return
        }
        setTitleAndNote()
        noteViewTitleLabel.textColor = Utilities.shared.getTextColor()
        noteTextView.backgroundColor = Utilities.shared.getBackgroundColor()
        view.backgroundColor = noteTextView.backgroundColor
    }
}

extension NoteViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        showFull()
        if textView.textColor == noteTextViewPlaceholderTextColor {
            textView.text = nil
            textView.textColor = Utilities.shared.getTextColor()
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
        saveButton.setTitle("noteSaveButtonLabel".localized, for: .normal)
    }
}
