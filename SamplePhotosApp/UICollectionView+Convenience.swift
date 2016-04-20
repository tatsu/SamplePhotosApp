//
//  UICollectionView+Convenience.swift
//  SamplePhotosApp
//
//  Created by Tatsuhiko Arai on 4/21/16.
//
//

import UIKit

extension UICollectionView {

    func aapl_indexPathsForElementsInRect(rect: CGRect) -> [NSIndexPath]? {
        guard let allLayoutAttributes = self.collectionViewLayout.layoutAttributesForElementsInRect(rect) where allLayoutAttributes.count > 0 else {
            return nil
        }

        var indexPaths = [NSIndexPath]()
        for layoutAttributes in allLayoutAttributes {
            indexPaths.append(layoutAttributes.indexPath)
        }

        return indexPaths
    }

}