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

    override func viewDidLoad() {
        super.viewDidLoad()
        realm = try! Realm()
        
        let gesture = UIPanGestureRecognizer.init(target: self, action: #selector(NotesViewController.panGesture))
        view.addGestureRecognizer(gesture)
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//       super.viewWillAppear(animated)
//       prepareBackgroundView()
//    }
    
    func initHighlightedText(id: String) {
        selectedHighlightedTextId = id
        
        if let highlightedText = realm.objects(HighlightedText.self).filter("id = '\(selectedHighlightedTextId)'").first {
            textView.text = highlightedText.note
        }
    }
    
    func show() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            let frame = self?.view.frame
            let yComponent = UIScreen.main.bounds.height - 200
            self?.view.frame = CGRect(x: 0, y: yComponent, width: frame!.width, height: frame!.height)
        }
    }
    
//    func prepareBackgroundView() {
//
//        let blurEffect = UIBlurEffect.init(style: .dark)
//        let visualEffect = UIVisualEffectView.init(effect: blurEffect)
//        let bluredView = UIVisualEffectView.init(effect: blurEffect)
//        bluredView.contentView.addSubview(visualEffect)
//
//        visualEffect.frame = UIScreen.main.bounds
//        bluredView.frame = UIScreen.main.bounds
//
//        view.insertSubview(bluredView, at: 0)
//    }
    
    @objc func panGesture(recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: view)
        let y = view.frame.minY
        view.frame = CGRect(x: 0, y: y + translation.y, width: view.frame.width, height: view.frame.height)
        recognizer.setTranslation(CGPoint.zero, in: view)
    }
}
