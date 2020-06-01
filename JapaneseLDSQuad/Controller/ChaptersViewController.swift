//
//  ChaptersViewController.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/3/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit
import RealmSwift

class ChaptersViewController: UIViewController {
    
    var targetBook: Book!
    var targetBookName: String!
    var counters: Results<Scripture>!
    var titles: Results<Scripture>!
    var chapterType = Constants.ChapterType.number
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        setSettingsBarButton()
        navigationItem.title = targetBookName
        chapterType = getChapterType()
        counters = targetBook.child_scriptures.filter("verse = 'counter'")
        if chapterType == Constants.ChapterType.title {
            titles = targetBook.child_scriptures.filter("verse = 'title'")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.estimatedRowHeight = CGFloat(Constants.TextSize.standard)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = tableView.tableFooterView ?? UIView(frame: CGRect.zero)
        reload()
    }
    
    func initTargetBook(targetBook: Book) {
        self.targetBook = targetBook
        targetBookName = targetBook.name_primary
    }
    
    fileprivate func getChapterType() -> String {
        if targetBook.link.hasPrefix("gs")
            || targetBook.link.hasPrefix("jst")
            || targetBook.link.hasPrefix("hymns") {
            return Constants.ChapterType.title
        }
        return Constants.ChapterType.number
    }
}

extension ChaptersViewController: SettingsViewDelegate {

    func reload() {
        tableView.reloadData()
    }
}

extension ChaptersViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection: Int) -> Int {
        return counters.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: Constants.ReuseID.chapterCell)
        let cellColor = Utilities.shared.getCellColor()
        
        tableView.backgroundColor = cellColor
        cell.backgroundColor = cellColor
        
        var cellTextLabel = counters[indexPath.row].scripture_primary
        if let titles = titles {
            cellTextLabel += " \(titles[indexPath.row].scripture_primary.tagsRemoved)"
        }
        cell.textLabel?.text = cellTextLabel
        cell.textLabel?.font = Utilities.shared.getFont()
        cell.textLabel?.textColor = Utilities.shared.getTextColor()
        
        if targetBook.link.hasPrefix("gs") { return cell }
        
        if Utilities.shared.dualEnabled {
            var cellDetailTextLabel = counters[indexPath.row].scripture_secondary
            if let titles = titles {
                cellDetailTextLabel += " \(titles[indexPath.row].scripture_secondary.tagsRemoved)"
            }
            cell.detailTextLabel?.text = cellDetailTextLabel
            cell.detailTextLabel?.font = Utilities.shared.getFont(multiplySizeBy: 0.6)
            cell.detailTextLabel?.textColor = .gray
        }
        return cell
    }
}

extension ChaptersViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let viewController = storyboard?.instantiateViewController(
            withIdentifier: Constants.StoryBoardID.pages) as? PagesViewController else {
                return
        }
        viewController.initData(targetScriptureData: TargetScriptureData(book: targetBook, chapter: indexPath.row + 1))
        navigationController?.pushViewController(viewController, animated: true)
    }
}

