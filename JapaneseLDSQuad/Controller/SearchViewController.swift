//
//  SearchViewController.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/2/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit
import RealmSwift

class SearchViewController: UIViewController {
    
    var realm: Realm!
    var message: UILabel!
    var searchResultsList: Results<Scripture>!
    var searchActive = false
    var currentSearchText = ""
    var currentSegmentIndex = "1"
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchSegmentControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        realm = try! Realm()
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        title = "searchViewTitle".localized
        initializeNoResultsMessage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.estimatedRowHeight = CGFloat(Constants.FontSize.regular)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = tableView.tableFooterView ?? UIView(frame: CGRect.zero)
//        reload()
    }
    
    @IBAction func searchSegmentControlValueChanged(_ sender: Any) {
        updateSearchResults()
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
//        delegate?.updateAdditionalFeatureBarButtons()
//        searchBar.resignFirstResponder()
//        self.dismiss(animated: true, completion: nil)
//    }
//
//    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
//        return UIModalPresentationStyle.none
//    }
    
    func initializeNoResultsMessage() {
        message = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
        message.numberOfLines = 4
        message.text = "noSearchResultsLabel".localized
        message.textAlignment = .center
        message.textColor = Constants.FontColor.night
        
        updateNoResultsMessageBackgroundColor()
        
        tableView.backgroundView = message
    }
    
    func updateNoResultsMessageBackgroundColor() {
        message.backgroundColor = UserDefaults.standard.bool(forKey: Constants.Config.night) ?
            Constants.BackgroundColor.night : Constants.BackgroundColor.day
    }
    
    func updateSearchBarStyle() {
        let nightModeEnabled = UserDefaults.standard.bool(forKey: Constants.Config.night)
        searchBar.barStyle = nightModeEnabled ? .black : .default
        searchSegmentControl.backgroundColor = nightModeEnabled ?
            Constants.BackgroundColor.nightSearchBar : Constants.BackgroundColor.daySearchBar
    }
    
    func reload() {
        updateSearchBarStyle()
        updateNoResultsMessageBackgroundColor()
        tableView.reloadData()
    }
}

//extension SearchViewController: UpperBarButtonsDelegate {
//
//    func reload() {
//        updateDualSwitch()
//        updateSearchBarStyle()
//        updateNoResultsMessageBackgroundColor()
//        tableView.reloadData()
//    }
//}

extension SearchViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.pages) as? PagesViewController {
            let scripture = searchResultsList[indexPath.row]
            viewController.initData(targetBook: scripture.parent_book,
                                    targetChapter: scripture.chapter,
                                    targetVerse: scripture.verse)
            navigationController?.pushViewController(viewController, animated: true)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        searchBar.resignFirstResponder()
    }
}


extension SearchViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection: Int) -> Int {
        if searchActive {
            return searchResultsList.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        let cellColor = UserDefaults.standard.bool(forKey: Constants.Config.night) ?
            Constants.CellColor.night : Constants.CellColor.day
        
        let font = UserDefaults.standard.bool(forKey: Constants.Config.font) ?
            Constants.Font.min : Constants.Font.kaku
        let fontSize = Constants.FontSize.regular * UserDefaults.standard.double(forKey: Constants.Config.size)
        
        let scripture = searchResultsList[indexPath.row]
        let hymnsCell = scripture.parent_book.link.hasPrefix("hymns")
        let gsCell = scripture.parent_book.link.hasPrefix("gs")
        let jstCell = scripture.parent_book.link.hasPrefix("jst")
        let contCell = scripture.parent_book.link.hasSuffix("_cont")
        
        tableView.backgroundColor = cellColor
        cell.backgroundColor = cellColor
        
        var cellTextLabel: String!
        var hymnFound: Results<Scripture>!
        var gsFound: Results<Scripture>!
        var jstFound: Results<Scripture>!
        
        if hymnsCell {
            hymnFound = scripture.parent_book.child_scriptures.filter("chapter = \(scripture.chapter)")
            let title = hymnFound.filter("verse = 'title'").first!.scripture_primary.tagsRemoved
            let counter = hymnFound.filter("verse = 'counter'").first!.scripture_primary
            cellTextLabel = "賛美歌 \(counter) \(title) \(scripture.verse)番"
        } else if gsCell {
            gsFound = scripture.parent_book.child_scriptures.filter("chapter = \(scripture.chapter)")
            let title = gsFound.filter("verse = 'title'").first!.scripture_primary.tagsRemoved
            cellTextLabel = "聖句ガイド「\(title)」\(scripture.verse)段落目"
        } else if jstCell {
            jstFound = scripture.parent_book.child_scriptures.filter("chapter = \(scripture.chapter)")
            let title = jstFound.filter("verse = 'title'").first!.scripture_primary.tagsRemoved.replacingOccurrences(of: "：.*", with: "", options: .regularExpression)
            cellTextLabel = "\(title) : \(scripture.verse)"
        } else if contCell {
            cellTextLabel = "\(scripture.parent_book.parent_book.name_primary) \(scripture.parent_book.name_primary) \(scripture.verse)段落目"
        } else {
            cellTextLabel = "\(scripture.parent_book.name_primary) \(scripture.chapter) : \(scripture.verse)"
        }
        
        if Constants.PaidContent.books.contains(scripture.parent_book.link) {
            cell.isUserInteractionEnabled = PurchaseManager.shared.isPurchased
            cell.textLabel?.isEnabled = PurchaseManager.shared.isPurchased
            cell.detailTextLabel?.isEnabled = PurchaseManager.shared.isPurchased
        }
        
        cell.textLabel?.text = cellTextLabel
        cell.textLabel?.font = UIFont(name: font, size: CGFloat(fontSize))
        cell.textLabel?.textColor = UserDefaults.standard.bool(forKey: Constants.Config.night) ?
            Constants.FontColor.night : Constants.FontColor.day
        
        if UserDefaults.standard.bool(forKey: Constants.Config.dual) {
            var cellDetailTextLabel: String!
            
            if hymnsCell {
                hymnFound = scripture.parent_book.child_scriptures.filter("chapter = \(scripture.chapter)")
                let title = hymnFound.filter("verse = 'title'").first!.scripture_secondary.tagsRemoved
                let counter = hymnFound.filter("verse = 'counter'").first!.scripture_secondary
                cellDetailTextLabel = "HYMN \(counter) \(title) Verse \(scripture.verse)"
            }
            else if gsCell {
                return cell
            }
            else if jstCell {
                jstFound = scripture.parent_book.child_scriptures.filter("chapter = \(scripture.chapter)")
                let title = jstFound.filter("verse = 'title'").first!.scripture_secondary.tagsRemoved.replacingOccurrences(of: ":.*", with: "", options: .regularExpression)
                cellDetailTextLabel = "\(title) : \(scripture.verse)"
            }
            else if contCell {
                cellDetailTextLabel = "\(scripture.parent_book.parent_book.name_secondary) \(scripture.parent_book.name_secondary) Paragraph \(scripture.verse)"
            }
            else {
                cellDetailTextLabel = "\(scripture.parent_book.name_secondary) \(scripture.chapter) : \(scripture.verse)"
            }
            
            cell.detailTextLabel?.text = cellDetailTextLabel
            cell.detailTextLabel?.font = UIFont(name: font, size: CGFloat(fontSize) / 2)
            cell.detailTextLabel?.textColor = UIColor.gray
        }
        return cell
    }
}


extension SearchViewController: UIScrollViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchBar.resignFirstResponder()
    }
}


extension SearchViewController: UISearchBarDelegate {
    
    func updateSearchResults() {
        
//      TODO: Remove this in production
//        if currentSearchText == Constants.Keys.AllFeaturesDebug {
//            PurchaseManager.shared.enablePurchase(purchased: true)
//        }
        
        if currentSearchText.isEmpty {
            searchActive = false
            message.isHidden = false
        }
        else {
            let searchQueryPrimary = "scripture_primary_raw CONTAINS '\(currentSearchText)'"
            let searchQuerySecondary = "scripture_secondary_raw CONTAINS[c] '\(currentSearchText)'"
            
            let selectedSegmentIndex = searchSegmentControl.selectedSegmentIndex
            let grandParentBookQuery = selectedSegmentIndex == searchSegmentControl.numberOfSegments - 1 ?
                "NOT parent_book.parent_book.id IN {'1', '2', '3', '4', '5'}" : "parent_book.parent_book.id = '\(selectedSegmentIndex + 1)'"
            
            searchResultsList = realm.objects(Scripture.self)
                .filter("(\(searchQuerySecondary) OR \(searchQueryPrimary)) AND \(grandParentBookQuery)").sorted(byKeyPath: "id")
            
            searchActive = searchResultsList.count > 0
            message.isHidden = searchActive
        }
        
        reload()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        currentSearchText = searchText
        updateSearchResults()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
