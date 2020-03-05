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
    
    var highlights: Results<HighlightedText>!
    var noHighlightsLabel: UILabel!

    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        realm = try! Realm()
        collectionView.dataSource = self
        collectionView.delegate = self
        if let layout = collectionView?.collectionViewLayout as? HighlightsViewLayout {
            layout.delegate = self
        }
        setSettingsBarButton()
        navigationItem.title = "highlightsViewTitle".localized
        noHighlightsLabel = getNoHighlightsMessageLabel()
        highlights = realm.objects(HighlightedText.self).sorted(byKeyPath: "date")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.clearLayoutCache()
            self.collectionView?.reloadData()
        }
    }
    
    func getNoHighlightsMessageLabel() -> UILabel {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: collectionView.bounds.size.width, height: collectionView.bounds.size.height))
        label.numberOfLines = 4
        label.text = "noHighlightsLabel".localized
        label.textAlignment = .center
        label.textColor = Constants.TextColor.night
        collectionView.backgroundView = label
        return label
    }
    
    func updateCollectionBackgroundColor() {
        collectionView?.backgroundColor = Utilities.shared.getBackgroundColor()
    }
}

extension HighlightsViewController: SettingsViewDelegate {
    
    func reload() {
        if let highlights = highlights {
            noHighlightsLabel.isHidden = highlights.count > 0
        }
        updateCollectionBackgroundColor()
        clearLayoutCache()
        collectionView.reloadData()
    }
}

extension HighlightsViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return highlights.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.ReuseID.highlightCell, for: indexPath) as? HighlightCell else { return HighlightCell() }
        cell.update(highlight: highlights[indexPath.row])
        cell.layoutIfNeeded()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let viewController = storyboard?.instantiateViewController(withIdentifier: Constants.StoryBoardID.pages) as? PagesViewController {
            let highlight = highlights[indexPath.row]
            viewController.initData(scripture: highlight.highlighted_scripture.scripture)
            navigationController?.pushViewController(viewController, animated: true)
        }
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

extension HighlightsViewController: HighlightsViewLayoutDelegate {
    
    func collectionView(_ collectionView: UICollectionView, heightForLabelAt indexPath: IndexPath) -> CGFloat {
        let highlight = highlights[indexPath.item]
        return getLabelHeight(text: Locale.current.languageCode == Constants.Language.primary
            ? "\(highlight.name_primary)"
            : "\(highlight.name_secondary)", labelType: HighlightRegularTextLabel.self)
            + getLabelHeight(text: highlight.text, labelType: HighlightSmallTextLabel.self)
            + getLabelHeight(text: highlight.note, labelType: HighlightRegularTextLabel.self)
            + Constants.Size.highlightCellLabelVerticalPadding
    }
    
    func getLabelHeight(text: String, labelType: UILabel.Type) -> CGFloat {
        let labelWidth = collectionView.collectionViewLayout.collectionViewContentSize.width / CGFloat(Constants.Count.columnsForHighlightsView)
            - Constants.Size.highlightCellPadding * 2
            - Constants.Size.highlightCellLabelHorizontalPadding * 2
        let label = labelType.init(frame: CGRect(x: 0, y: 0, width: labelWidth, height: CGFloat.greatestFiniteMagnitude))
        label.text = text
        label.sizeToFit()
        return label.frame.height + Constants.Size.highlightCellLabelVerticalPadding
    }
    
    func clearLayoutCache() {
        if let layout = collectionView?.collectionViewLayout as? HighlightsViewLayout {
            layout.clearCache()
        }
    }
}
