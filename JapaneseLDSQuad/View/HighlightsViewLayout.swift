//
//  HighlightsViewLayout.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/17/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit

protocol HighlightsViewLayoutDelegate: AnyObject {
  func collectionView(_ collectionView: UICollectionView, heightForLabelAt indexPath: IndexPath) -> CGFloat
}

class HighlightsViewLayout: UICollectionViewLayout {
    
    weak var delegate: HighlightsViewLayoutDelegate?

    private let numberOfColumns = Constants.Count.columnsForHighlightsView
    private let cellPadding: CGFloat = 6

    private var cache: [UICollectionViewLayoutAttributes] = []

    private var contentHeight: CGFloat = 0
    private var contentWidth: CGFloat {
        guard let collectionView = collectionView else { return 0 }
        let insets = collectionView.contentInset
        return collectionView.bounds.width - (insets.left + insets.right)
    }

    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }
    
    override func prepare() {
        guard cache.isEmpty, let collectionView = collectionView else { return }
        
        let columnWidth = contentWidth / CGFloat(numberOfColumns)
        var xOffset: [CGFloat] = []
        for column in 0..<numberOfColumns {
            xOffset.append(CGFloat(column) * columnWidth)
        }
        var column = 0
        var yOffset: [CGFloat] = .init(repeating: 0, count: numberOfColumns)
        
        for item in 0..<collectionView.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(item: item, section: 0)
            let labelHeight = delegate?.collectionView(collectionView, heightForLabelAt: indexPath) ?? 180
            let height = cellPadding * 2 + labelHeight
            let frame = CGRect(x: xOffset[column],
                               y: yOffset[column],
                               width: columnWidth,
                               height: height)
            let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)
        
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = insetFrame
            cache.append(attributes)
        
            contentHeight = max(contentHeight, frame.maxY)
            yOffset[column] = yOffset[column] + height
        
            column = column < (numberOfColumns - 1) ? (column + 1) : 0
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var visibleLayoutAttributes: [UICollectionViewLayoutAttributes] = []
      
        // Loop through the cache and look for items in the rect
        for attributes in cache {
            if attributes.frame.intersects(rect) {
                visibleLayoutAttributes.append(attributes)
            }
        }
        return visibleLayoutAttributes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[indexPath.item]
    }
}
