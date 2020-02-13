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
    var noResultsLabel: UILabel!
    var searchResults: Results<Scripture>!
    var searchActive = false
    var currentSearchText = ""
    var currentSegmentIndex = "1"
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchResultsSegmentedControl: UISegmentedControl!
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
        super.viewWillAppear(animated)
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
        noResultsLabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
        noResultsLabel.numberOfLines = 4
        noResultsLabel.text = "noSearchResultsLabel".localized
        noResultsLabel.textAlignment = .center
        noResultsLabel.textColor = Constants.FontColor.night
        updateTableBackgroundColor()
        tableView.backgroundView = noResultsLabel
    }
    
    func updateTableBackgroundColor() {
        noResultsLabel.backgroundColor = UserDefaults.standard.bool(forKey: Constants.Config.night)
            ? Constants.BackgroundColor.night
            : Constants.BackgroundColor.day
    }
    
    func updateSearchBarStyle() {
        let nightModeEnabled = UserDefaults.standard.bool(forKey: Constants.Config.night)
        searchBar.barStyle = nightModeEnabled ? .black : .default
        searchResultsSegmentedControl.backgroundColor = nightModeEnabled
            ? Constants.BackgroundColor.nightSearchBar
            : Constants.BackgroundColor.daySearchBar
    }
    
    func reload() {
        updateSearchBarStyle()
        updateTableBackgroundColor()
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
            let scripture = searchResults[indexPath.row]
            viewController.initData(scripture: scripture)
            navigationController?.pushViewController(viewController, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
        searchBar.resignFirstResponder()
    }
}


extension SearchViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection: Int) -> Int {
        return searchActive ? searchResults.count : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "searchResultCell")
        let cellColor = UserDefaults.standard.bool(forKey: Constants.Config.night)
            ? Constants.CellColor.night
            : Constants.CellColor.day
        let font = UserDefaults.standard.bool(forKey: Constants.Config.font)
            ? Constants.Font.min
            : Constants.Font.kaku
        let fontSize = Constants.FontSize.regular * UserDefaults.standard.double(forKey: Constants.Config.size)
        
        tableView.backgroundColor = cellColor
        cell.backgroundColor = cellColor
        
        let scripture = searchResults[indexPath.row]
        let contentType = AppUtility.shared.getContentType(targetBook: scripture.parent_book)
        let scriptures = scripture.parent_book.child_scriptures.filter("chapter = \(scripture.chapter)")
        let builder = AppUtility.shared.getContentBuilder(scriptures: scriptures, contentType: contentType)
        let cellTextLabel = builder.buildSearchResultText(scripture: scripture)
        
        cell.textLabel?.text = cellTextLabel
        cell.textLabel?.font = UIFont(name: font, size: CGFloat(fontSize))
        cell.textLabel?.textColor = UserDefaults.standard.bool(forKey: Constants.Config.night)
            ? Constants.FontColor.night
            : Constants.FontColor.day
        
        if UserDefaults.standard.bool(forKey: Constants.Config.dual) {
            let cellDetailTextLabel = builder.buildSearchResultDetailText(scripture: scripture)
            cell.detailTextLabel?.text = cellDetailTextLabel
            cell.detailTextLabel?.font = UIFont(name: font, size: CGFloat(fontSize) / 2)
            cell.detailTextLabel?.textColor = UIColor.gray
        }
        
        if Constants.PaidContent.books.contains(scripture.parent_book.link) {
            cell.isUserInteractionEnabled = PurchaseManager.shared.isPurchased
            cell.textLabel?.isEnabled = PurchaseManager.shared.isPurchased
            cell.detailTextLabel?.isEnabled = PurchaseManager.shared.isPurchased
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
        if currentSearchText.isEmpty {
            searchActive = false
            noResultsLabel.isHidden = false
        } else {
            let searchQueryPrimary = "scripture_primary_raw CONTAINS '\(currentSearchText)'"
            let searchQuerySecondary = "scripture_secondary_raw CONTAINS[c] '\(currentSearchText)'"
            let selectedSegmentIndex = searchResultsSegmentedControl.selectedSegmentIndex
            let grandParentBookQuery = selectedSegmentIndex == searchResultsSegmentedControl.numberOfSegments - 1
                ? "NOT parent_book.parent_book.id IN {'1', '2', '3', '4', '5'}"
                : "parent_book.parent_book.id = '\(selectedSegmentIndex + 1)'"
            
            searchResults = realm.objects(Scripture.self).filter("(\(searchQuerySecondary) OR \(searchQueryPrimary)) AND \(grandParentBookQuery)").sorted(byKeyPath: "id")
            searchActive = searchResults.count > 0
            noResultsLabel.isHidden = searchActive
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
