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
    
    let cellHorizontalPaddingSize: CGFloat = 6
    
    override func viewDidLoad() {
        super.viewDidLoad()
        realm = try! Realm()
        collectionView.dataSource = self
        collectionView.delegate = self
        setSettingsBarButton()
        navigationItem.title = "highlightsViewTitle".localized
        noHighlightsLabel = getNoHighlightssMessageLabel()
        highlights = realm.objects(HighlightedText.self).sorted(byKeyPath: "date")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }
    
    func getNoHighlightssMessageLabel() -> UILabel {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: collectionView.bounds.size.width, height: collectionView.bounds.size.height))
        label.numberOfLines = 4
        label.text = "noHighlightsLabel".localized
        label.textAlignment = .center
        label.textColor = Constants.FontColor.night
        collectionView.backgroundView = label
        return label
    }
    
    func updateCollectionBackgroundColor() {
        collectionView.backgroundColor =  UserDefaults.standard.bool(forKey: Constants.Config.night)
            ? Constants.BackgroundColor.night
            : Constants.BackgroundColor.day
    }
}

extension HighlightsViewController: SettingsChangeDelegate {
    
    func reload() {
        noHighlightsLabel.isHidden = highlights.count > 0
        updateCollectionBackgroundColor()
        collectionView.reloadData()
    }
}

extension HighlightsViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return highlights.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.ReuseID.highlightCell, for: indexPath) as? HighlightCell else { return HighlightCell() }
        cell.update(highlight: highlights[indexPath.row])
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = collectionView.bounds.width / 2 - cellHorizontalPaddingSize * 2
        return CGSize(width: cellWidth, height: cellWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: cellHorizontalPaddingSize, bottom: 0, right: cellHorizontalPaddingSize)
    }
}
