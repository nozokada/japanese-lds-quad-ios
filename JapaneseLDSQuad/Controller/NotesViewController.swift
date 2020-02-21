//
//  NotesViewController.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/19/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit
import RealmSwift

class NotesViewController: UIViewController {
    
    var realm: Realm!
    
    @IBOutlet weak var notesViewTitleLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var noteTextView: UITextView!
    
    var highlightedText: HighlightedText?
    var bottomY: CGFloat = UIScreen.main.bounds.height

    override func viewDidLoad() {
        super.viewDidLoad()
        realm = try! Realm()
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(panGesture))
        view.addGestureRecognizer(gesture)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reload()
        debugPrint(noteTextView.frame)
        noteTextView.frame.size = CGSize(width: noteTextView.frame.width, height: view.frame.height / 3 - notesViewTitleLabel.frame.height - 100 - 16 - 16)
        debugPrint(noteTextView.frame)
    }
    
    func initHighlightedText(id: String) {
        if let highlightedText = realm.objects(HighlightedText.self).filter("id = '\(id)'").first {
            self.highlightedText = highlightedText
        }
        reload()
    }
    
    func setTitleAndNote() {
        notesViewTitleLabel.text = Locale.current.languageCode == Constants.LanguageCode.primary
            ? highlightedText?.name_primary
            : highlightedText?.name_secondary
        noteTextView.text = highlightedText?.text
    }
    
    func show() {
        if let superview = view.superview {
            bottomY = superview.frame.maxY
        }
        UIView.animate(withDuration: 0.3) {
            let frame = self.view.frame
            let y = self.bottomY - frame.height / 3
            self.view.frame = CGRect(x: 0, y: y, width: frame.width, height: frame.height)
        }
    }
    
    func showFull() {
        UIView.animate(withDuration: 0.3) {
            let frame = self.view.frame
            let y = self.bottomY - frame.height / 2
            self.view.frame = CGRect(x: 0, y: y, width: frame.width, height: frame.height)
        }
    }
    
    func hide() {
        UIView.animate(withDuration: 0.3) {
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
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        try! realm.write {
            highlightedText?.note = noteTextView.text
        }
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        hide()
    }
}

extension NotesViewController: SettingsChangeDelegate {
    func reload() {
        setTitleAndNote()
        view.backgroundColor = AppUtility.shared.getCurrentBackgroundColor()
    }
}
