//
//  TextToSpeechDelegate.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/22/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit

protocol ScripturesToSpeechDelegate {
    
    func scroll()
    
    func updateScripturesToSpeech()
}

extension ScripturesToSpeechDelegate where Self: UIViewController {

    func setSpeechBarButton() {
        let speechButton = UIBarButtonItem(image: UIImage(named: "Headphones"), style: .plain, target: self, action: #selector(presentSpeechViewController(sender:)))
        if let barButtonItems = navigationItem.rightBarButtonItems {
            navigationItem.rightBarButtonItems = barButtonItems + [speechButton]
        } else {
            navigationItem.rightBarButtonItem = speechButton
        }
    }
}

extension UIViewController {
    
    func addSpeechViewController() {
        guard let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.speech) as? SpeechViewController else { return }
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
        viewController.delegate = self as? ScripturesToSpeechDelegate
        
        let height = view.frame.height
        let width  = view.frame.width
        viewController.view.frame = CGRect(x: 0, y: 0 - view.frame.height, width: width, height: height)
    }
    
    @objc func presentSpeechViewController(sender: UIBarButtonItem) {
        if StoreObserver.shared.allFeaturesUnlocked {
            guard let speechViewController = getSpeechViewController() else { return }
            if speechViewController.isHidden {
                speechViewController.show()
            } else {
                speechViewController.hide()
            }
        } else {
            presentPuchaseViewController()
        }
    }
    
    func getSpeechViewController() -> SpeechViewController? {
        let speechViewControllers = children.filter { $0 is SpeechViewController } as! [SpeechViewController]
        return speechViewControllers.first
    }
}
