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
    
    var bookmarks: Results<Bookmark>!
    var noBookmarksLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        setSettingsBarButton()
        navigationItem.title = "bookmarksViewTitle".localized
        noBookmarksLabel = getNoBookmarksMessageLabel()
        bookmarks = BookmarksManager.shared.getAll()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.estimatedRowHeight = CGFloat(Constants.TextSize.standard)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = tableView.tableFooterView ?? UIView(frame: CGRect.zero)
        FirestoreManager.shared.delegate = self
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
    
    func firestoreManagerDidSucceed() {
        reload()
    }
}

extension BookmarksViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let viewController = storyboard?.instantiateViewController(
            withIdentifier: Constants.StoryBoardID.pages) as? PagesViewController else {
            return
        }
        let bookmark = bookmarks[indexPath.row]
        viewController.initData(scripture: bookmark.scripture)
        navigationController?.pushViewController(viewController, animated: true)
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
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: Constants.ReuseID.bookmarkCell, for: indexPath) as? BookmarkCell else {
            return BookmarkCell()
        }
        cell.update(bookmark: bookmarks[indexPath.row])
        cell.layoutIfNeeded()
        return cell
    }
}
