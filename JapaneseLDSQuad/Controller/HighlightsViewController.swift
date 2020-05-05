//
//  HighlightsViewController.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/16/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit
import RealmSwift

class HighlightsViewController: UIViewController {
    
    var realm: Realm!
    var results: Results<HighlightedText>!
    var searchText = ""
    var searchNoficationToken: NotificationToken? = nil

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var noHighlightsLabel: UILabel!
    var spinner: MainIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        realm = try! Realm()
        searchBar.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        if let layout = collectionView?.collectionViewLayout as? HighlightsViewLayout {
            layout.delegate = self
        }
        setSettingsBarButton()
        navigationItem.title = "highlightsViewTitle".localized
        spinner = MainIndicatorView(parentView: view)
        noHighlightsLabel = getNoHighlightsMessageLabel()
        results = realm.objects(HighlightedText.self).sorted(byKeyPath: "date")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        FirestoreManager.shared.delegate = self
        reload()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.clearLayoutCache()
            self.collectionView?.reloadData()
        }
    }
    
    fileprivate func getNoHighlightsMessageLabel() -> UILabel {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: collectionView.bounds.size.width, height: collectionView.bounds.size.height))
        label.numberOfLines = 4
        label.text = "noHighlightsLabel".localized
        label.textAlignment = .center
        label.textColor = Constants.TextColor.night
        collectionView.backgroundView = label
        return label
    }
    
    fileprivate func updateNoHighlightsMessageLabel() {
        if let highlights = results {
            noHighlightsLabel.isHidden = highlights.count > 0
            if !searchText.isEmpty {
                noHighlightsLabel.text = "noHighlightResultsLabel".localized
            } else {
                noHighlightsLabel.text = "noHighlightsLabel".localized
            }
        }
    }
    
    fileprivate func updateCollectionBackgroundColor() {
        collectionView?.backgroundColor = Utilities.shared.getBackgroundColor()
    }
    
    fileprivate func updateSearchBarStyle() {
        searchBar.barStyle = Utilities.shared.nightModeEnabled ? .black : .default
    }
}

extension HighlightsViewController: SettingsViewDelegate {
    
    func reload() {
        updateNoHighlightsMessageLabel()
        updateSearchBarStyle()
        updateCollectionBackgroundColor()
        clearLayoutCache()
        collectionView.reloadData()
    }
}

extension HighlightsViewController: FirestoreManagerDelegate {
    
    func firestoreManagerDidSucceed() {
        reload()
    }
}

extension HighlightsViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return results.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.ReuseID.highlightCell, for: indexPath) as? HighlightCell else { return HighlightCell() }
        cell.update(highlight: results[indexPath.row])
        cell.layoutIfNeeded()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        if let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.pages) as? PagesViewController {
            let highlight = results[indexPath.row]
            viewController.initData(scripture: highlight.highlighted_scripture.scripture)
            navigationController?.pushViewController(viewController, animated: true)
        }
        searchBar.resignFirstResponder()
    }
}

extension HighlightsViewController: HighlightsViewLayoutDelegate {
    
    func collectionView(_ collectionView: UICollectionView, heightForLabelAt indexPath: IndexPath) -> CGFloat {
        let highlight = results[indexPath.item]
        return getLabelHeight(text: Utilities.shared.getLanguage() == Constants.Language.primary
            ? "\(highlight.name_primary)"
            : "\(highlight.name_secondary)", labelType: HighlightRegularTextLabel.self)
            + getLabelHeight(text: highlight.text, labelType: HighlightSmallTextLabel.self)
            + getLabelHeight(text: highlight.note, labelType: HighlightRegularTextLabel.self)
            + Constants.Size.highlightCellLabelVerticalPadding
    }
    
    fileprivate func getLabelHeight(text: String, labelType: UILabel.Type) -> CGFloat {
        let labelWidth = collectionView.collectionViewLayout.collectionViewContentSize.width / CGFloat(Constants.Count.columnsForHighlightsView)
            - Constants.Size.highlightCellPadding * 2
            - Constants.Size.highlightCellLabelHorizontalPadding * 2
        let label = labelType.init(frame: CGRect(x: 0, y: 0, width: labelWidth, height: CGFloat.greatestFiniteMagnitude))
        label.text = text
        label.sizeToFit()
        return label.frame.height + Constants.Size.highlightCellLabelVerticalPadding
    }
    
    fileprivate func clearLayoutCache() {
        if let layout = collectionView?.collectionViewLayout as? HighlightsViewLayout {
            layout.clearCache()
        }
    }
}

extension HighlightsViewController: UIScrollViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchBar.resignFirstResponder()
    }
}

extension HighlightsViewController: UISearchBarDelegate {
    
    fileprivate func updateResults() {
        if !searchText.isEmpty {
            let nameQuery = "name_primary CONTAINS '\(searchText)' OR name_secondary CONTAINS '\(searchText)'"
            let noteQuery = "note CONTAINS '\(searchText)'"
            let searchQuery = "\(nameQuery) OR \(noteQuery)"
            results = realm.objects(HighlightedText.self).filter(searchQuery)
        } else {
            results = realm.objects(HighlightedText.self).sorted(byKeyPath: "date")
        }
        searchNoficationToken = results.observe { _ in
            self.reload()
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        updateResults()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
