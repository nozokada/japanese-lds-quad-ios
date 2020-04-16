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
        FirestoreManager.shared.delegate = self
        setSettingsBarButton()
        navigationItem.title = "bookmarksViewTitle".localized
        noBookmarksLabel = getNoBookmarksMessageLabel()
        bookmarks = realm.objects(Bookmark.self).sorted(byKeyPath: "date")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.estimatedRowHeight = CGFloat(Constants.TextSize.standard)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = tableView.tableFooterView ?? UIView(frame: CGRect.zero)
        reload()
    }
    
    fileprivate func getNoBookmarksMessageLabel() -> UILabel {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
        label.numberOfLines = 4
        label.text = "noBookmarksLabel".localized
        label.textAlignment = .center
        label.textColor = Constants.TextColor.night
        tableView.backgroundView = label
        return label
    }
    
    fileprivate func updateTableBackgroundColor() {
        tableView.backgroundColor = Utilities.shared.getBackgroundColor()
    }
}

extension BookmarksViewController: SettingsViewDelegate {

    func reload() {
        noBookmarksLabel.isHidden = bookmarks.count > 0
        updateTableBackgroundColor()
        tableView.reloadData()
    }
}

extension BookmarksViewController: FirestoreManagerDelegate {
    func firestoreManagerDidSync() {
        reload()
    }
}

extension BookmarksViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.pages) as? PagesViewController {
            let bookmark = bookmarks[indexPath.row]
            viewController.initData(scripture: bookmark.scripture)
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
            BookmarksManager.shared.update(id: bookmarks[indexPath.row].id)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            noBookmarksLabel.isHidden = bookmarks.count > 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: Constants.ReuseID.bookmarkCell)
        let cellColor = Utilities.shared.getCellColor()
        
        tableView.backgroundColor = cellColor
        cell.backgroundColor = cellColor
        
        let bookmark = bookmarks[indexPath.row]
        cell.textLabel?.text = bookmark.name_primary
        cell.textLabel?.font = Utilities.shared.getFont()
        cell.textLabel?.textColor = Utilities.shared.getTextColor()
        cell.textLabel?.numberOfLines = 0
        
        if Utilities.shared.dualEnabled {
            let cellDetailTextLabel = bookmarks[indexPath.row].name_secondary
            cell.detailTextLabel?.text = cellDetailTextLabel
            cell.detailTextLabel?.font = Utilities.shared.getFont(multiplySizeBy: 0.6)
            cell.detailTextLabel?.textColor = .gray
            cell.detailTextLabel?.numberOfLines = 0
        }
        cell.layoutIfNeeded()
        
        var dateLabelHeight = CGFloat.zero
        if let textLabelHeight = cell.textLabel?.frame.height {
            dateLabelHeight += textLabelHeight
        }
        if let detailTextLabelHeight = cell.detailTextLabel?.frame.height {
            dateLabelHeight += detailTextLabelHeight
        }
        
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("yMMMdE jm")
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: cell.frame.width / 3, height: dateLabelHeight))
        label.text = formatter.string(from: bookmark.date as Date)
        label.font = Utilities.shared.getFont(multiplySizeBy: 0.6)
        label.textColor = .gray
        label.numberOfLines = 0
        
        cell.accessoryView = label
        
        return cell
    }
}
