//
//  AssetGridViewController.swift
//  SamplePhotosApp
//
//  Created by Tatsuhiko Arai on 4/16/16.
//
//

import UIKit
import PhotosUI

private let CellReuseIdentifier = "Cell"
private var AssetGridThumbnailSize: CGSize!

class AssetGridViewController: UICollectionViewController, PHPhotoLibraryChangeObserver {

    var assetsFetchResults: PHFetchResult?
    var assetCollection :PHAssetCollection?

    @IBOutlet weak var addButton: UIBarButtonItem!
    var imageManager: PHCachingImageManager!
    var previousPreheatRect: CGRect!

    override func awakeFromNib() {
        self.imageManager = PHCachingImageManager()
        self.resetCachedAssets()

        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
    }

    deinit {
        PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Determine the size of the thumbnails to request from the PHCachingImageManager
        let scale = UIScreen.mainScreen().scale
        let cellSize = (self.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
        AssetGridThumbnailSize = CGSizeMake(cellSize.width * scale, cellSize.height * scale)

        // Add button to the navigation bar if the asset collection supports adding content.
        if let assetCollection = self.assetCollection where assetCollection.canPerformEditOperation(.AddContent) {
            self.navigationItem.rightBarButtonItem = self.addButton
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        // Begin caching assets in and around collection view's visible rect.
        self.updateCachedAssets()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        // self.collectionView!.registerClass(AAPLGridViewCell.self, forCellWithReuseIdentifier: CellReuseIdentifier)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Configure the destination AAPLAssetViewController.
        guard let assetViewController = segue.destinationViewController as? AssetViewController, let cell =  sender as? UICollectionViewCell, let indexPath = self.collectionView!.indexPathForCell(cell) else {
            return
        }

        assetViewController.asset = self.assetsFetchResults?[indexPath.item] as? PHAsset
        assetViewController.assetCollection = self.assetCollection
    }

    // MARK: - PHPhotoLibraryChangeObserver

    func photoLibraryDidChange(changeInstance: PHChange) {
        // Check if there are changes to the assets we are showing.
        guard let assetsFetchResults = self.assetsFetchResults, let collectionChanges = changeInstance.changeDetailsForFetchResult(assetsFetchResults) else {
            return
        }

        /*
         Change notifications may be made on a background queue. Re-dispatch to the
         main queue before acting on the change as we'll be updating the UI.
         */
        dispatch_async(dispatch_get_main_queue()) {
            [unowned self] in
            // Get the new fetch result.
            self.assetsFetchResults = collectionChanges.fetchResultAfterChanges

            if !collectionChanges.hasIncrementalChanges || collectionChanges.hasMoves {
                // Reload the collection view if the incremental diffs are not available
                self.collectionView!.reloadData()
            } else {
                /*
                 Tell the collection view to animate insertions and deletions if we
                 have incremental diffs.
                 */
                self.collectionView!.performBatchUpdates({
                    if let removedIndexes = collectionChanges.removedIndexes where removedIndexes.count > 0 {
                        if let indexPaths = removedIndexes.aapl_indexPathsFromIndexesWithSection(0) {
                            self.collectionView!.deleteItemsAtIndexPaths(indexPaths)
                        }
                    }

                    if let insertedIndexes = collectionChanges.insertedIndexes where insertedIndexes.count > 0 {
                        if let indexPaths = insertedIndexes.aapl_indexPathsFromIndexesWithSection(0) {
                            self.collectionView!.insertItemsAtIndexPaths(indexPaths)
                        }
                    }

                    if let changedIndexes = collectionChanges.changedIndexes where changedIndexes.count > 0 {
                        if let indexPaths = changedIndexes.aapl_indexPathsFromIndexesWithSection(0) {
                            self.collectionView!.reloadItemsAtIndexPaths(indexPaths)
                        }
                    }
                }, completion: nil)
            }
            
            self.resetCachedAssets()
        }
    }

    // MARK: - UICollectionViewDataSource

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.assetsFetchResults?.count ?? 0
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        // Dequeue an AAPLGridViewCell.
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CellReuseIdentifier, forIndexPath: indexPath) as! GridViewCell

        if let asset = self.assetsFetchResults?[indexPath.item] as? PHAsset {
            cell.representedAssetIdentifier = asset.localIdentifier

            // Add a badge to the cell if the PHAsset represents a Live Photo.
            if asset.mediaSubtypes.contains(.PhotoLive) {
                // Add Badge Image to the cell to denote that the asset is a Live Photo.
                let badge = PHLivePhotoView.livePhotoBadgeImageWithOptions(.OverContent)
                cell.livePhotoBadgeImage = badge
            }

            // Request an image for the asset from the PHCachingImageManager.
            self.imageManager.requestImageForAsset(asset, targetSize: AssetGridThumbnailSize, contentMode: .AspectFill, options: nil, resultHandler: {
                (result: UIImage?, info: [NSObject : AnyObject]?) -> Void in
                // Set the cell's thumbnail image if it's still showing the same asset.
                if cell.representedAssetIdentifier == asset.localIdentifier {
                    cell.thumbnailImage = result
                }
            })
        }

        return cell
    }

    // MARK: - UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */

    // MARK: - UIScrollViewDelegate

    override func scrollViewDidScroll(scrollView: UIScrollView) {
        // Update cached assets for the new visible area.
        self.updateCachedAssets()
    }

    // MARK: - Asset Caching

    func resetCachedAssets() {
        self.imageManager.stopCachingImagesForAllAssets()
        self.previousPreheatRect = CGRectZero
    }

    func updateCachedAssets() {
        guard isViewLoaded() && view.window != nil else {
            return
        }

        // The preheat window is twice the height of the visible rect.
        var preheatRect = self.collectionView!.bounds
        preheatRect = CGRectInset(preheatRect, 0.0, -0.5 * CGRectGetHeight(preheatRect))

        /*
         Check if the collection view is showing an area that is significantly
         different to the last preheated area.
         */
        let delta = fabs(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect))
        if delta > CGRectGetHeight(self.collectionView!.bounds) / 3.0 {

            // Compute the assets to start caching and to stop caching.
            var addedIndexPaths = [NSIndexPath]()
            var removedIndexPaths = [NSIndexPath]()

            computeDifferenceBetweenRect(self.previousPreheatRect, andRect: preheatRect, removedHandler: {
                (removedRect: CGRect) ->Void in
                if let indexPaths = self.collectionView!.aapl_indexPathsForElementsInRect(removedRect) {
                    removedIndexPaths += indexPaths
                }
            }, addedHandler: {
                (addedRect: CGRect) -> Void in
                if let indexPaths = self.collectionView!.aapl_indexPathsForElementsInRect(addedRect) {
                    addedIndexPaths += indexPaths
                }
            })

            // Update the assets the PHCachingImageManager is caching.
            if let assetsToStartCaching = assetsAtIndexPaths(addedIndexPaths) {
                self.imageManager.startCachingImagesForAssets(assetsToStartCaching, targetSize: AssetGridThumbnailSize, contentMode: .AspectFill, options: nil)
            }

            if let assetsToStopCaching = assetsAtIndexPaths(removedIndexPaths) {
                self.imageManager.stopCachingImagesForAssets(assetsToStopCaching, targetSize: AssetGridThumbnailSize, contentMode: .AspectFill, options:nil)
            }
            
            // Store the preheat rect to compare against in the future.
            self.previousPreheatRect = preheatRect
        }
    }

    func computeDifferenceBetweenRect(oldRect: CGRect, andRect newRect: CGRect, removedHandler: (removedRect: CGRect) -> Void, addedHandler: (addedRect: CGRect) -> Void) {
        if CGRectIntersectsRect(newRect, oldRect) {
            let oldMaxY = CGRectGetMaxY(oldRect)
            let oldMinY = CGRectGetMinY(oldRect)
            let newMaxY = CGRectGetMaxY(newRect)
            let newMinY = CGRectGetMinY(newRect)

            if newMaxY > oldMaxY {
                let rectToAdd = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY))
                addedHandler(addedRect: rectToAdd)
            }

            if oldMinY > newMinY {
                let rectToAdd = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY))
                addedHandler(addedRect: rectToAdd)
            }

            if newMaxY < oldMaxY {
                let rectToRemove = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY))
                removedHandler(removedRect: rectToRemove)
            }

            if oldMinY < newMinY {
                let rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY))
                removedHandler(removedRect: rectToRemove)
            }
        } else {
            addedHandler(addedRect: newRect)
            removedHandler(removedRect: oldRect)
        }
    }

    func assetsAtIndexPaths(indexPaths: NSArray) -> [PHAsset]? {
        guard indexPaths.count > 0 else {
            return nil
        }

        var assets = [PHAsset]()
        for indexPath in indexPaths {
            if let asset = self.assetsFetchResults?[indexPath.item] as? PHAsset {
                assets.append(asset)
            }
        }

        return assets
    }

    // MARK: - Actions

    @IBAction func handleAddButtonItem(sender: AnyObject) {
        guard let assetCollection = self.assetCollection else {
            return
        }

        // Create a random dummy image.
        let rect = rand() % 2 == 0 ? CGRectMake(0, 0, 400, 300) : CGRectMake(0, 0, 300, 400)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 1.0)
        UIColor(hue: (CGFloat(rand()) % 100) / 100, saturation: 1.0, brightness: 1.0, alpha: 1.0).setFill()
        UIRectFillUsingBlendMode(rect, .Normal)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        // Add it to the photo library
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
            if let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: assetCollection) {
                let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(image)
                if let placeholder = assetChangeRequest.placeholderForCreatedAsset {
                    assetCollectionChangeRequest.addAssets([placeholder])
                }
            }
        }, completionHandler: {
                (success: Bool, error: NSError?) -> Void in
                if !success {
                    NSLog("Error creating asset: \(error)")
                }
        })
    }
}
