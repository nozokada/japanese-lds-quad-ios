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
    var searchText = ""
    var chapterText = ""
    var verseText = ""
    var currentSegmentIndex = "1"
    var searchNoficationToken: NotificationToken? = nil
    var filterNotificationToken: NotificationToken? = nil
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var passageLookupView: UIView!
    @IBOutlet weak var chapterTextField: MainTextField!
    @IBOutlet weak var verseTextField: MainTextField!
    @IBOutlet weak var searchResultCountLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    var noResultsLabel: UILabel!
    var spinner: MainIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
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
    
    fileprivate func showActivityIndicator() {
        noResultsLabel.isHidden = true
        spinner.startAnimating()
    }
    
    fileprivate func hideActivityIndicator() {
        spinner.stopAnimating()
    }
    
    fileprivate func getNoResultsMessageLabel() -> UILabel {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
        label.numberOfLines = 4
        label.text = "noSearchResultsLabel".localized
        label.textAlignment = .center
        label.textColor = Constants.TextColor.night
        tableView.backgroundView = label
        return label
    }
    
    fileprivate func updateSearchResultCount() {
        searchResultCountLabel.text = searchText.isEmpty && chapterText.isEmpty && verseText.isEmpty
            ? ""
            : "\(filteredResults.count) \("searchMatches".localized)"
    }
    
    fileprivate func updatePassageLookupView() {
        passageLookupView.backgroundColor = Utilities.shared.getBackgroundColor()
        chapterTextField.customizeViews()
        verseTextField.customizeViews()
        chapterTextField.placeholder = "chapterTextFieldPlaceholder".localized
        verseTextField.placeholder = "verseTextFieldPlaceholder".localized
    }
    
    @IBAction func chapterTextFieldEditingChanged(_ sender: Any) {
        chapterText = chapterTextField.text ?? ""
        if !chapterText.isNumeric || !verseText.isNumeric {
            return
        }
        updateResults()
    }
    
    @IBAction func verseTextFieldEditingChanged(_ sender: Any) {
        verseText = verseTextField.text ?? ""
        if !chapterText.isNumeric || !verseText.isNumeric {
            return
        }
        updateResults()
    }
    
    @IBAction func chapterTextFieldTouchedDown(_ sender: Any) {
        if !PurchaseManager.shared.allFeaturesUnlocked {
            presentPuchaseViewController()
        }
    }
    
    @IBAction func verseTextFieldTouchedDown(_ sender: Any) {
        if !PurchaseManager.shared.allFeaturesUnlocked {
            presentPuchaseViewController()
        }
    }
}

extension SearchViewController: SettingsViewDelegate {

    func reload() {
        if let results = results {
            noResultsLabel.isHidden = results.count > 0
        }
        updatePassageLookupView()
        updateSearchResultCount()
        searchBar.barStyle = Utilities.shared.nightModeEnabled ? .black : .default
        tableView.backgroundColor = Utilities.shared.getBackgroundColor()
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
        
        guard let viewController = storyboard?.instantiateViewController(
            withIdentifier: Constants.StoryBoardID.pages) as? PagesViewController else {
                return
        }
        viewController.initData(scripture: scripture)
        navigationController?.pushViewController(viewController, animated: true)
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
        cell.backgroundColor = Utilities.shared.getCellColor()
        
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
    
    fileprivate func updateResults() {
        showActivityIndicator()
        
        var searchQuery = ""
        if !chapterText.isEmpty || !verseText.isEmpty {
            let searchQueryChapter = chapterText.isEmpty
                ? "" : "chapter = \(chapterText) AND "
            let searchQueryVerse = verseText.isEmpty
                ? "id LIKE '??????'" : "verse = '\(verseText)'"
            searchQuery += "\(searchQueryChapter) \(searchQueryVerse)"
            searchQuery += searchText.isEmpty ? " OR " : " AND "
        }
        
        let searchQueryPrimary = "scripture_primary_raw CONTAINS '\(searchText)'"
        let searchQuerySecondary = "scripture_secondary_raw CONTAINS[c] '\(searchText)'"
        searchQuery += "(\(searchQuerySecondary) OR \(searchQueryPrimary))"
        
        results = Utilities.shared.getScriptures(query: searchQuery)
        searchNoficationToken = results.observe { _ in
            self.updateSegmentResults()
        }
    }
    
    fileprivate func updateSegmentResults() {
        guard let results = results else {
            return
        }
        let selectedSegmentIndex = searchBar.selectedScopeButtonIndex
        let filterQuery = selectedSegmentIndex != searchBar.scopeButtonTitles!.count - 1
            ? "parent_book.parent_book.id = '\(selectedSegmentIndex + 1)'"
            : "NOT parent_book.parent_book.id IN {'1', '2', '3', '4', '5'}"
        filteredResults = results.filter(filterQuery)
        filterNotificationToken = filteredResults.observe { _ in
            self.reload()
            self.updateSearchResultCount()
            self.hideActivityIndicator()
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        updateResults()
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        updateSegmentResults()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
