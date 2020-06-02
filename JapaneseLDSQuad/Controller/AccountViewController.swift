//
//  AccountViewController.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 3/17/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit
import Firebase

class AccountViewController: UITableViewController {

    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var lastSyncDateLabel: UILabel!
    @IBOutlet weak var signOutButton: MainButton!
    @IBOutlet weak var syncSwitchLabel: UILabel!
    @IBOutlet weak var syncSwitch: UIButton!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    var user: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let user = AuthenticationManager.shared.currentUser else {
            presentSignInViewController()
            return
        }
        self.user = user
        navigationItem.title = "accountViewTitle".localized
        usernameLabel.text = user.displayName
        emailLabel.text = user.email
        syncSwitchLabel.text = "syncButtonLabel".localized
        signOutButton.setTitle("signOutButtonLabel".localized, for: .normal)
        setSettingsBarButton()
        setSyncSwitchState()
        spinner.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AuthenticationManager.shared.delegate = self
        FirestoreManager.shared.delegate = self
        reload()
        tableView.tableFooterView = UIView()
    }
    
    fileprivate func setSyncSwitchState() {
        let state = FirestoreManager.shared.syncEnabled
        syncSwitch.setImage(state ? #imageLiteral(resourceName: "ToggleOn") : #imageLiteral(resourceName: "ToggleOff"), for: .normal)
    }
    
    fileprivate func alert(title: String, message: String, close: Bool = false) {
        let alertController = Utilities.shared.alert(view: view, title: title, message: message, handler: nil)
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func presentSignInViewController() {
        guard let viewController = storyboard?.instantiateViewController(
            withIdentifier: Constants.StoryBoardID.signIn) else {
            return
        }
        navigationController?.setViewControllers([viewController], animated: false)
        navigationItem.title = "signInViewTitle".localized
    }
    
    fileprivate func updateLastSyncDateLabel() {
        lastSyncDateLabel.text = "\("lastSyncTitleLabel".localized): \(Utilities.shared.formattedLastSyncedDate)"
    }
    
    fileprivate func enableSync() {
        spinner.isHidden = false
        spinner.startAnimating()
        syncSwitch.setImage(#imageLiteral(resourceName: "ToggleOn"), for: .normal)
        FirestoreManager.shared.enableSync()
    }
    
    fileprivate func disableSync() {
        syncSwitch.setImage(#imageLiteral(resourceName: "ToggleOff"), for: .normal)
        FirestoreManager.shared.disableSync()
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = Utilities.shared.getCellColor()
    }
    
    @IBAction func syncSwitchToggled(_ sender: Any) {
        if FirestoreManager.shared.syncEnabled {
            disableSync()
        } else {
            guard let viewController = storyboard?.instantiateViewController(
                withIdentifier: Constants.StoryBoardID.dialogue) as? DialogueViewController else {
                return
            }
            viewController.delegate = self
            viewController.initData(message: "syncWarningLabel".localized)
            viewController.modalPresentationStyle = .overFullScreen
            viewController.modalTransitionStyle = .crossDissolve
            present(viewController, animated: true)
        }
    }
    
    @IBAction func signOutButtonTapped(_ sender: Any) {
        AuthenticationManager.shared.signOut(completion: presentSignInViewController)
    }
}

extension AccountViewController: SettingsViewDelegate {
    
    func reload() {
        let fontColor = Utilities.shared.getTextColor()
        usernameLabel.textColor = fontColor
        syncSwitchLabel.textColor = fontColor
        tableView.backgroundColor = Utilities.shared.getBackgroundColor()
        tableView.reloadData()
        updateLastSyncDateLabel()
    }
}

extension AccountViewController: AuthenticationManagerDelegate {
    
    func authenticationManagerDidSucceed() {
    }
    
    func authenticationManagerDidReceiveMessage(_ message: String) {
        alert(title: "signOutError".localized, message: message)
    }
}

extension AccountViewController: FirestoreManagerDelegate {
    
    func firestoreManagerDidSucceed() {
        spinner.stopAnimating()
        spinner.isHidden = true
        updateLastSyncDateLabel()
    }
}

extension AccountViewController: DialogueViewDelegate {
    
    func dialogueViewDidReceiveOK() {
        enableSync()
    }
}
