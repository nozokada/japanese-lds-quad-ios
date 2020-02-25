//
//  HighlightChangeDelegate.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/25/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit

protocol HighlightChangeDelegate {
    
    func removeHighlight(id: String)
}

extension HighlightChangeDelegate where Self: UIViewController {
    
    func addNoteViewController() {
        guard let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.notes) as? NoteViewController else { return }
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
        viewController.delegate = self
        
        let height = view.frame.height
        let width  = view.frame.width
        viewController.view.frame = CGRect(x: 0, y: view.frame.maxY, width: width, height: height)
    }
}

extension UIViewController {
    
    func getNoteViewController() -> NoteViewController? {
        let noteViewControllers = children.filter { $0 is NoteViewController } as! [NoteViewController]
        return noteViewControllers.first
    }
}
