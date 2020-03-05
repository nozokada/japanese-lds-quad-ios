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
    
    var results: Results<Scripture>!
    var filteredResults: Results<Scripture>!
    var currentSearchText = ""
    var currentSegmentIndex = "1"
    var searchNoficationToken: NotificationToken? = nil
    var filterNotificationToken: NotificationToken? = nil
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchResultsSegmentedControl: UISegmentedControl!
    @IBOutlet weak var segmentedControlView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    var noResultsLabel: UILabel!
    var spinner: MainIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        setSettingsBarButton()
        navigationItem.title = "searchViewTitle".localized
        spinner = MainIndicatorView(parentView: view)
        noResultsLabel = getNoResultsMessageLabel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.estimatedRowHeight = CGFloat(Constants.TextSize.standard)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = tableView.tableFooterView ?? UIView(frame: CGRect.zero)
        reload()
    }
    
    func showActivityIndicator() {
        noResultsLabel.isHidden = true
        spinner.startAnimating()
    }
    
    func hideActivityIndicator() {
        spinner.stopAnimating()
    }
    
    func getNoResultsMessageLabel() -> UILabel {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
        label.numberOfLines = 4
        label.text = "noSearchResultsLabel".localized
        label.textAlignment = .center
        label.textColor = Constants.TextColor.night
        tableView.backgroundView = label
        return label
    }
    
    func updateTableBackgroundColor() {
        tableView.backgroundColor = Utilities.shared.getBackgroundColor()
    }
    
    func updateSearchBarStyle() {
        let nightModeEnabled = Utilities.shared.nightModeEnabled
        searchBar.barStyle = nightModeEnabled ? .black : .default
        searchResultsSegmentedControl.backgroundColor = nightModeEnabled
            ? Constants.BackgroundColor.nightSearchBar
            : Constants.BackgroundColor.daySearchBar
        segmentedControlView.backgroundColor = searchResultsSegmentedControl.backgroundColor
    }
    
    func updateSearchBarPrompt() {
        searchBar.prompt = currentSearchText.isEmpty
            ? nil
            : "\(filteredResults.count) \("searchMatches".localized)"
    }
    
    @IBAction func searchSegmentControlValueChanged(_ sender: Any) {
        updateSegmentResults()
        updateSearchBarPrompt()
    }
}

extension SearchViewController: SettingsViewDelegate {

    func reload() {
        if let results = results {
            noResultsLabel.isHidden = results.count > 0
        }
        updateSearchBarStyle()
        updateTableBackgroundColor()
        tableView.reloadData()
    }
}

extension SearchViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let scripture = filteredResults[indexPath.row]
        
        if Utilities.shared.isPaid(book: scripture.parent_book) {
            if !PurchaseManager.shared.allFeaturesUnlocked {
                presentPuchaseViewController()
                return
            }
        }
        
        if let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.pages) as? PagesViewController {
            
            viewController.initData(scripture: scripture)
            navigationController?.pushViewController(viewController, animated: true)
        }
        searchBar.resignFirstResponder()
    }
}


extension SearchViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection: Int) -> Int {
        if let results = filteredResults {
            return results.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let results = filteredResults, results.count > 0 else { return UITableViewCell() }
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: Constants.ReuseID.searchResultCell)
        let cellColor = Utilities.shared.getCellColor()
        
        tableView.backgroundColor = cellColor
        cell.backgroundColor = cellColor
        
        let scripture = results[indexPath.row]
        let contentType = Utilities.shared.getContentType(targetBook: scripture.parent_book)
        let scriptures = scripture.parent_book.child_scriptures.filter("chapter = \(scripture.chapter)")
        let builder = Utilities.shared.getContentBuilder(scriptures: scriptures, contentType: contentType)
        let cellTextLabel = builder.buildSearchResultText(scripture: scripture)
        
        cell.textLabel?.text = cellTextLabel
        cell.textLabel?.font = Utilities.shared.getFont()
        cell.textLabel?.textColor = Utilities.shared.getTextColor()
        
        if Utilities.shared.dualEnabled {
            let cellDetailTextLabel = builder.buildSearchResultDetailText(scripture: scripture)
            cell.detailTextLabel?.text = cellDetailTextLabel
            cell.detailTextLabel?.font = Utilities.shared.getFont(multiplySizeBy: 0.6)
            cell.detailTextLabel?.textColor = .gray
        }
        
        if Utilities.shared.isPaid(book: scripture.parent_book) {
            cell.textLabel?.isEnabled = PurchaseManager.shared.allFeaturesUnlocked
            cell.detailTextLabel?.isEnabled = PurchaseManager.shared.allFeaturesUnlocked
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
    
    func updateResults() {
        showActivityIndicator()
        let searchQueryPrimary = "scripture_primary_raw CONTAINS '\(currentSearchText)'"
        let searchQuerySecondary = "scripture_secondary_raw CONTAINS[c] '\(currentSearchText)'"
        
        let realm = try! Realm()
        results = realm.objects(Scripture.self).filter("\(searchQuerySecondary) OR \(searchQueryPrimary)")
        searchNoficationToken = results.observe { _ in
            self.updateSegmentResults()
        }
    }
    
    func updateSegmentResults() {
        guard let results = results else { return }
        let selectedSegmentIndex = searchResultsSegmentedControl.selectedSegmentIndex
        let filterQuery = selectedSegmentIndex != searchResultsSegmentedControl.numberOfSegments - 1
            ? "parent_book.parent_book.id = '\(selectedSegmentIndex + 1)'"
            : "NOT parent_book.parent_book.id IN {'1', '2', '3', '4', '5'}"
        filteredResults = results.filter(filterQuery)
        filterNotificationToken = filteredResults.observe { _ in
            self.reload()
            self.updateSearchBarPrompt()
            self.hideActivityIndicator()
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        currentSearchText = searchText
        updateResults()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
