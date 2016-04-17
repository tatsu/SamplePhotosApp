//
//  GridViewCell.swift
//  SamplePhotosApp
//
//  Created by Tatsuhiko Arai on 4/17/16.
//
//

import UIKit

class GridViewCell: UICollectionViewCell {
    var thumbnailImage: UIImage? {
        didSet {
            self.imageView.image = thumbnailImage
        }
    }

    var livePhotoBadgeImage: UIImage? {
        didSet {
            self.livePhotoBadgeImageView.image = livePhotoBadgeImage
        }
    }

    var representedAssetIdentifier: String?

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var livePhotoBadgeImageView: UIImageView!

    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = nil
        self.livePhotoBadgeImageView.image = nil
    }
}
