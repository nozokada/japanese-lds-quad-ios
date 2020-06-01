//
//  DialogueViewController.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 5/31/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit

class DialogueViewController: UIViewController {
    
    var delegate: DialogueViewDelegate?

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var okButton: MainButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func initData(message: String, hideCancel: Bool = false) {
        messageLabel.text = message
        okButton.setTitle("okButtonLabel".localized, for: .normal)
        cancelButton.setTitle("cancelButtonLabel".localized, for: .normal)
        cancelButton.isHidden = hideCancel
    }
    
    @IBAction func okButtonTapped(_ sender: Any) {
        delegate?.dialogueViewDidReceiveOK()
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        delegate?.dialogueViewDidReceiveCancel()
    }
}
