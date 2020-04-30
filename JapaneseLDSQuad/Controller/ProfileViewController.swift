//
//  ProfileViewController.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 3/17/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit
import Firebase

class ProfileViewController: UITableViewController {

    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var signOutButton: MainButton!
    @IBOutlet weak var syncSwitchLabel: UILabel!
    @IBOutlet weak var syncSwitch: UIButton!
    
    var user: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let user = AuthenticationManager.shared.currentUser else {
            presentSignInViewController()
            return
        }
        navigationItem.title = "profileViewTitle".localized
        usernameLabel.text = user.displayName
        emailLabel.text = user.email
        syncSwitchLabel.text = "syncButtonLabel".localized
        signOutButton.setTitle("signOutButtonLabel".localized, for: .normal)
        self.user = user
        setSettingsBarButton()
        setSyncSwitchState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AuthenticationManager.shared.delegate = self
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
        if let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.signIn) {
            navigationController?.setViewControllers([viewController], animated: false)
            navigationItem.title = "signInViewTitle".localized
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        tableView.backgroundColor = Utilities.shared.getBackgroundColor()
        cell.backgroundColor = Utilities.shared.getCellColor()
        let fontColor = Utilities.shared.getTextColor()
        usernameLabel.textColor = fontColor
        syncSwitchLabel.textColor = fontColor
    }
    
    @IBAction func syncSwitchToggled(_ sender: Any) {
        let state = FirestoreManager.shared.syncEnabled
        syncSwitch.setImage(state ? #imageLiteral(resourceName: "ToggleOff") : #imageLiteral(resourceName: "ToggleOn") , for: .normal)
        if !state {
            FirestoreManager.shared.enableSync()
        } else {
            FirestoreManager.shared.disableSync()
        }
    }
    
    @IBAction func signOutButtonTapped(_ sender: Any) {
        AuthenticationManager.shared.signOut(completion: presentSignInViewController)
    }
}

extension ProfileViewController: SettingsViewDelegate {
    
    func reload() {
        tableView.reloadData()
    }
}

extension ProfileViewController: AuthenticationManagerDelegate {
    
    func authenticationManagerDidSucceed() {
    }
    
    func authenticationManagerDidReceiveMessage(_ message: String) {
        alert(title: "signOutError".localized, message: message)
    }
}
