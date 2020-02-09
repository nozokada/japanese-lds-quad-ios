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
    var chaptersList: Results<Scripture>!
    var titlesList: Results<Scripture>!
    var chapterType = Constants.ChapterType.number
    
    @IBOutlet weak var tableView: UITableView!
//    @IBOutlet weak var dualSwitch: UIBarButtonItem!
//    @IBOutlet weak var passageLookUpViewButton: UIBarButtonItem!
//    @IBOutlet weak var highlightsViewButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = targetBookName
        setChapterType()
        chaptersList = targetBook.child_scriptures.filter("verse = 'counter'")
        if chapterType == Constants.ChapterType.title {
            titlesList = targetBook.child_scriptures.filter("verse = 'title'")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.estimatedRowHeight = CGFloat(Constants.FontSize.regular)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = tableView.tableFooterView ?? UIView(frame: CGRect.zero)
//        reload()
    }
    
    func initTargetBook(targetBook: Book) {
        self.targetBook = targetBook
        targetBookName = targetBook.name_primary
    }
    
    func setChapterType() {
        if targetBook.link.hasPrefix("gs") || targetBook.link.hasPrefix("jst") || targetBook.link.hasPrefix("hymns") {
            chapterType = Constants.ChapterType.title
        } else {
            chapterType = Constants.ChapterType.number
        }
    }
    
//    @IBAction func rootButtonTapped(_ sender: Any) {
//        popToRootViewController()
//    }
//
//    @IBAction func passageLookupViewButtonTapped(_ sender: Any) {
//        presentPassageLookupViewController()
//    }
//
//    @IBAction func searchButtonTapped(_ sender: Any) {
//        presentSearchViewController()
//    }
//
//    @IBAction func bookmarksButtonTapped(_ sender: Any) {
//        presentBookmarksViewController()
//    }
//
//    @IBAction func highlightsButtonTapped(_ sender: Any) {
//        presentHighlightsViewController()
//    }
//
//    @IBAction func settingsButtonTapped(_ sender: UIBarButtonItem) {
//        presentSettingsTableViewController(sender)
//    }
//
//    @IBAction func dualSwitchToggled(_ sender: Any) {
//        changeDualMode()
//    }
//
//    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
//        return UIModalPresentationStyle.none
//    }
}


//extension ChaptersViewController: UpperBarButtonsDelegate {
//
//    func reload() {
//        updateDualSwitch()
//        updateAdditionalFeatureBarButtons()
//        tableView.reloadData()
//    }
//}


extension ChaptersViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection: Int) -> Int {
        return chaptersList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        let cellColor = UserDefaults.standard.bool(forKey: Constants.Config.night) ? Constants.CellColor.night : Constants.CellColor.day
        
        var cellTextLabel = chaptersList[indexPath.row].scripture_primary
        if let titles = titlesList {
            cellTextLabel += " \(titles[indexPath.row].scripture_primary.tagsRemoved)"
        }
        
        let font = UserDefaults.standard.bool(forKey: Constants.Config.font) ? Constants.Font.min : Constants.Font.kaku
        let fontSize = Constants.FontSize.regular * UserDefaults.standard.double(forKey: Constants.Config.size)
        
        tableView.backgroundColor = cellColor
        cell.backgroundColor = cellColor
        
        cell.textLabel?.text = cellTextLabel
        cell.textLabel?.font = UIFont(name: font, size: CGFloat(fontSize))
        cell.textLabel?.textColor = UserDefaults.standard.bool(forKey: Constants.Config.night) ? Constants.FontColor.night : Constants.FontColor.day
        
        if targetBook.link.hasPrefix("gs") { return cell }
        
        if UserDefaults.standard.bool(forKey: Constants.Config.dual) {
            var cellDetailTextLabel = chaptersList[indexPath.row].scripture_secondary
            if let titles = titlesList {
                cellDetailTextLabel += " \(titles[indexPath.row].scripture_secondary.tagsRemoved)"
            }
            cell.detailTextLabel?.text = cellDetailTextLabel
            cell.detailTextLabel?.font = UIFont(name: font, size: CGFloat(fontSize) / 2)
            cell.detailTextLabel?.textColor = UIColor.gray
        }
        return cell
    }
}


extension ChaptersViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.pages) as? PagesViewController {
            viewController.initTargetBookAndChapter(targetBook: targetBook, targetChapter: indexPath.row + 1, targetVerse: nil)
            self.navigationController?.pushViewController(viewController, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

