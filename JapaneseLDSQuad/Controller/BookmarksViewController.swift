//
//  BookmarksViewController.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/2/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit
import RealmSwift

class BookmarksViewController: UIViewController {
    
    var realm: Realm!
    
    var bookmarks: Results<Bookmark>!
    var noBookmarksLabel: UILabel!

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        realm = try! Realm()
        tableView.delegate = self
        tableView.dataSource = self
        title = "bookmarksViewTitle".localized
        initializeNoBookmarksMessage()
        bookmarks = realm.objects(Bookmark.self).sorted(byKeyPath: "date")
        noBookmarksLabel.isHidden = bookmarks.count > 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.estimatedRowHeight = CGFloat(Constants.FontSize.regular)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = tableView.tableFooterView ?? UIView(frame: CGRect.zero)
        reload()
    }
    
//    @IBAction func settingsButtonTapped(_ sender: UIBarButtonItem) {
//        presentSettingsTableViewController(sender)
//    }
//
//    @IBAction func dualSwitchToggled(_ sender: Any) {
//        changeDualMode()
//    }
//
//    @IBAction func closeButtonTapped(_ sender: Any) {
//        self.dismiss(animated: true, completion: nil)
//    }
    
//    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
//        return UIModalPresentationStyle.none
//    }
    
    func initializeNoBookmarksMessage() {
        noBookmarksLabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
        noBookmarksLabel.numberOfLines = 4
        noBookmarksLabel.text = "noBookmarksLabel".localized
        noBookmarksLabel.textAlignment = .center
        noBookmarksLabel.textColor = Constants.FontColor.night
        updateNoBookmarksMessageBackgroundColor()
        tableView.backgroundView = noBookmarksLabel
    }
    
    func updateNoBookmarksMessageBackgroundColor() {
        noBookmarksLabel.backgroundColor =  UserDefaults.standard.bool(forKey: Constants.Config.night)
            ? Constants.BackgroundColor.night
            : Constants.BackgroundColor.day
    }
    
    func reload() {
        updateNoBookmarksMessageBackgroundColor()
        tableView.reloadData()
    }
}


//extension BookmarksViewController: UpperBarButtonsDelegate {
//
//    func reload() {
//        updateDualSwitch()
//        updateNoBookmarksMessageBackgroundColor()
//        tableView.reloadData()
//    }
//}


extension BookmarksViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.pages) as? PagesViewController {
            let bookmark = bookmarks[indexPath.row]
            viewController.initData(targetBook: bookmark.scripture.parent_book, targetChapter: bookmark.scripture.chapter, targetVerse: bookmark.scripture.verse)
            navigationController?.pushViewController(viewController, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}


extension BookmarksViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection: Int) -> Int {
        return bookmarks.count
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            BookmarksManager.shared.addOrDeleteBookmark(id: bookmarks[indexPath.row].id)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            noBookmarksLabel.isHidden = bookmarks.count > 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "bookmarkCell")
        let cellColor = UserDefaults.standard.bool(forKey: Constants.Config.night)
            ? Constants.CellColor.night
            : Constants.CellColor.day
        let font = UserDefaults.standard.bool(forKey: Constants.Config.font)
            ? Constants.Font.min
            : Constants.Font.kaku
        let fontSize = Constants.FontSize.regular * UserDefaults.standard.double(forKey: Constants.Config.size)
        
        tableView.backgroundColor = cellColor
        cell.backgroundColor = cellColor
        
        let bookmark = bookmarks[indexPath.row]
        cell.textLabel?.text = bookmark.name_primary
        cell.textLabel?.font = UIFont(name: font, size: CGFloat(fontSize))
        cell.textLabel?.textColor = UserDefaults.standard.bool(forKey: Constants.Config.night)
            ? Constants.FontColor.night
            : Constants.FontColor.day
        cell.textLabel?.numberOfLines = 0;
        cell.textLabel?.lineBreakMode = .byWordWrapping;
        
        if UserDefaults.standard.bool(forKey: Constants.Config.dual) {
            let cellDetailTextLabel = bookmarks[indexPath.row].name_secondary
            cell.detailTextLabel?.text = cellDetailTextLabel
            cell.detailTextLabel?.font = UIFont(name: font, size: CGFloat(fontSize) / 2)
            cell.detailTextLabel?.textColor = .gray
            cell.detailTextLabel?.numberOfLines = 0;
            cell.detailTextLabel?.lineBreakMode = .byWordWrapping;
        }
        
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("yMMMdE jms")
        let label = UILabel.init(frame: CGRect(x: 0, y: 0, width: 100, height: 20))
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.text = formatter.string(from: bookmark.date as Date)
        label.textColor = .gray
        label.font = UIFont(name: font, size: CGFloat(fontSize) / 2)
        cell.accessoryView = label
        
        return cell
    }
}
