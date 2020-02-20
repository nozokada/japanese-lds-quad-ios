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
    
    @IBOutlet weak var textView: UITextView!
    
    var selectedHighlightedTextId = ""
    var bottomY: CGFloat = UIScreen.main.bounds.height

    override func viewDidLoad() {
        super.viewDidLoad()
        realm = try! Realm()
        
        let gesture = UIPanGestureRecognizer.init(target: self, action: #selector(NotesViewController.panGesture))
        view.addGestureRecognizer(gesture)
    }
    
    func initHighlightedText(id: String) {
        selectedHighlightedTextId = id
        
        if let highlightedText = realm.objects(HighlightedText.self).filter("id = '\(selectedHighlightedTextId)'").first {
            textView.text = highlightedText.note
        }
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
}
