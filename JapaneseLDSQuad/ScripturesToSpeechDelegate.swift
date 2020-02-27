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
        let speechButton = UIBarButtonItem(image: UIImage(systemName: "headphones"), style: .plain, target: self, action: #selector(showOrHideSpeechControlPanel(sender:)))
        if let barButtonItems = navigationItem.rightBarButtonItems {
            navigationItem.rightBarButtonItems = barButtonItems + [speechButton]
        } else {
            navigationItem.rightBarButtonItem = speechButton
        }
    }
    
    func addSpeechViewController() {
        guard let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.speech) as? SpeechViewController else { return }
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
        viewController.delegate = self
        
        let height = view.frame.height
        let width  = view.frame.width
        viewController.view.frame = CGRect(x: 0, y: 0 - view.frame.height, width: width, height: height)
    }
}

extension UIViewController {
    
    @objc func showOrHideSpeechControlPanel(sender: UIBarButtonItem) {
        guard let speechViewController = getSpeechViewController() else { return }
 
        if speechViewController.isHidden {
            speechViewController.show()
        } else {
            speechViewController.hide()
        }
    }
    
    func getSpeechViewController() -> SpeechViewController? {
        let speechViewControllers = children.filter { $0 is SpeechViewController } as! [SpeechViewController]
        return speechViewControllers.first
    }
}
