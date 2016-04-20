//
//  NSIndexSet+Convenience.swift
//  SamplePhotosApp
//
//  Created by Tatsuhiko Arai on 4/20/16.
//
//

import UIKit

extension NSIndexSet {

    func aapl_indexPathsFromIndexesWithSection(section: Int) -> [NSIndexPath]? {
        var indexPaths = [NSIndexPath]()
        self.enumerateIndexesUsingBlock { (idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            indexPaths.append(NSIndexPath(forItem: idx, inSection: section))
        }

        return indexPaths.count > 0 ? indexPaths : nil
    }

}