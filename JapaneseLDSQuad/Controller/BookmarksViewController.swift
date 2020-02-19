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
        setSettingsBarButton()
        navigationItem.title = "bookmarksViewTitle".localized
        noBookmarksLabel = getNoBookmarksMessageLabel()
        bookmarks = realm.objects(Bookmark.self).sorted(byKeyPath: "date")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.estimatedRowHeight = CGFloat(Constants.TextSize.regular)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = tableView.tableFooterView ?? UIView(frame: CGRect.zero)
        reload()
    }
    
    func getNoBookmarksMessageLabel() -> UILabel {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
        label.numberOfLines = 4
        label.text = "noBookmarksLabel".localized
        label.textAlignment = .center
        label.textColor = Constants.TextColor.night
        tableView.backgroundView = label
        return label
    }
    
    func updateTableBackgroundColor() {
        tableView.backgroundColor =  UserDefaults.standard.bool(forKey: Constants.Config.night)
            ? Constants.BackgroundColor.night
            : Constants.BackgroundColor.day
    }
}

extension BookmarksViewController: SettingsChangeDelegate {

    func reload() {
        noBookmarksLabel.isHidden = bookmarks.count > 0
        updateTableBackgroundColor()
        tableView.reloadData()
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
            BookmarksManager.shared.addOrDeleteBookmark(id: bookmarks[indexPath.row].id)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            noBookmarksLabel.isHidden = bookmarks.count > 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: Constants.ReuseID.bookmarkCell)
        let cellColor = AppUtility.shared.getCurrentCellColor()
        
        tableView.backgroundColor = cellColor
        cell.backgroundColor = cellColor
        
        let bookmark = bookmarks[indexPath.row]
        cell.textLabel?.text = bookmark.name_primary
        cell.textLabel?.font = AppUtility.shared.getCurrentFont()
        cell.textLabel?.textColor = AppUtility.shared.getCurrentTextColor()
        cell.textLabel?.numberOfLines = 0;
        cell.textLabel?.lineBreakMode = .byWordWrapping;
        
        if UserDefaults.standard.bool(forKey: Constants.Config.dual) {
            let cellDetailTextLabel = bookmarks[indexPath.row].name_secondary
            cell.detailTextLabel?.text = cellDetailTextLabel
            cell.detailTextLabel?.font = AppUtility.shared.getCurrentFont(multiplySizeBy: 0.6)
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
        label.font = AppUtility.shared.getCurrentFont(multiplySizeBy: 0.5)
        cell.accessoryView = label
        
        return cell
    }
}
