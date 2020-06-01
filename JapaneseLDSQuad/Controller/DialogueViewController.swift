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
    var messageText: String?
    var showWithoutCancel: Bool = false

    @IBOutlet weak var modalView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var okButton: MainButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messageLabel.text = messageText
        okButton.setTitle("okButtonLabel".localized, for: .normal)
        if showWithoutCancel {
            cancelButton.isHidden = true
        } else {
            cancelButton.setTitle("cancelButtonLabel".localized, for: .normal)
        }
        addDropShadow()
    }
    
    func initData(message: String, withoutCancel: Bool = false) {
        messageText = message
        showWithoutCancel = withoutCancel
    }
    
    fileprivate func addDropShadow() {
        modalView.layer.shadowOpacity = 0.5
        modalView.layer.shadowOffset = .zero
    }
    
    @IBAction func okButtonTapped(_ sender: Any) {
        delegate?.dialogueViewDidReceiveOK()
        dismiss(animated: true)
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }
}
