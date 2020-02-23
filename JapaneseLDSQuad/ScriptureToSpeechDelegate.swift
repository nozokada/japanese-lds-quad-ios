//
//  TextToSpeechDelegate.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/22/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import Foundation
import RealmSwift

protocol ScriptureToSpeechDelegate {
    
    var speechVerses: Results<Scripture>? { get }
}

extension ScriptureToSpeechDelegate where Self: UIViewController {
    
    func setSpeechBarButton() {
        let speechButton = UIBarButtonItem(image: UIImage(systemName: "headphones"), style: .plain, target: self, action: #selector(PagesViewController.showSpeechControlPanel(sender:)))
        if let barButtonItems = navigationItem.rightBarButtonItems {
            navigationItem.rightBarButtonItems = barButtonItems + [speechButton]
        } else {
            navigationItem.rightBarButtonItem = speechButton
        }
    }
}

extension PagesViewController: ScriptureToSpeechDelegate {
    
    var speechVerses: Results<Scripture>? {
        get {
            guard let chapterId = targetChapterId else { return nil }
            return scripturesInBook.filter(
                "id BEGINSWITH '\(chapterId)' AND NOT verse IN {'title', 'counter', 'preface', 'intro', 'summary', 'date'}"
            ).sorted(byKeyPath: "id")
        }
    }
    
    @objc func showSpeechControlPanel(sender: UIBarButtonItem) {
        debugPrint("showSpeechControlPanel")
    }
}
