//
//  AssetViewController.swift
//  SamplePhotosApp
//
//  Created by Tatsuhiko Arai on 4/18/16.
//
//

import UIKit
import PhotosUI

private let AdjustmentFormatIdentifier = "com.example.apple-samplecode.SamplePhotosApp"

class AssetViewController: UIViewController, PHPhotoLibraryChangeObserver, PHLivePhotoViewDelegate {

    var asset: PHAsset?
    var assetCollection: PHAssetCollection?

    @IBOutlet weak var livePhotoView: PHLivePhotoView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet var playButton: UIBarButtonItem!
    @IBOutlet var space: UIBarButtonItem!
    @IBOutlet var trashButton: UIBarButtonItem!

    var playerLayer: AVPlayerLayer?
    // var lastTargetSize: CGSize?
    var playingHint: Bool = false

    deinit {
        PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.livePhotoView.delegate = self
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Set the appropriate toolbarItems based on the mediaType of the asset.
        if self.asset?.mediaType == .Video {
            self.showPlaybackToolbar()
        } else {
            self.showStaticToolbar()
        }

        // Enable the edit button if the asset can be edited.
        var isEditable = false
        if let asset = self.asset {
            isEditable = asset.canPerformEditOperation(.Properties) || asset.canPerformEditOperation(.Content)
        }
        self.editButton.enabled = isEditable

        // Enable the trash button if the asset can be deleted.
        var isTrashable = false
        if let assetCollection = self.assetCollection {
            isTrashable = assetCollection.canPerformEditOperation(.RemoveContent)
        } else if let asset = self.asset {
            isTrashable = asset.canPerformEditOperation(.Delete)
        }
        self.trashButton.enabled = isTrashable
        
        self.updateImage()
        
        self.view.layoutIfNeeded()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */

    // MARK: - View & Toolbar setup methods.

    func showLivePhotoView() {
        self.livePhotoView.hidden = false
        self.imageView.hidden = true
    }

    func showStaticPhotoView() {
        self.livePhotoView.hidden = true
        self.imageView.hidden = false
    }

    func showPlaybackToolbar() {
        self.toolbarItems = [self.playButton, self.space, self.trashButton]
    }

    func showStaticToolbar() {
        self.toolbarItems = [self.space, self.trashButton]
    }

    func targetSize() -> CGSize {
        let scale = UIScreen.mainScreen().scale
        let targetSize = CGSizeMake(CGRectGetWidth(self.imageView.bounds) * scale, CGRectGetHeight(self.imageView.bounds) * scale)
        return targetSize
    }

    // MARK: - ImageView/LivePhotoView Image Setting methods.

    func updateImage() {
        // self.lastTargetSize = self.targetSize()

        // Check the asset's `mediaSubtypes` to determine if this is a live photo or not.
        if let asset = self.asset where asset.mediaSubtypes.contains(.PhotoLive) {
            self.updateLiveImage()
        }
        else {
            self.updateStaticImage()
        }
    }

    func updateLiveImage() {
        guard let asset = self.asset else {
            return
        }

        // Prepare the options to pass when fetching the live photo.
        let livePhotoOptions = PHLivePhotoRequestOptions()
        livePhotoOptions.deliveryMode = .HighQualityFormat
        livePhotoOptions.networkAccessAllowed = true
        livePhotoOptions.progressHandler = { [unowned self] (progress: Double, error: NSError?, stop: UnsafeMutablePointer<ObjCBool>, info: [NSObject : AnyObject]?) in
            /*
             Progress callbacks may not be on the main thread. Since we're updating
             the UI, dispatch to the main queue.
             */
            dispatch_async(dispatch_get_main_queue()) {
                self.progressView.progress = Float(progress)
            }
        }

        // Request the live photo for the asset from the default PHImageManager.
        PHImageManager.defaultManager().requestLivePhotoForAsset(asset, targetSize: self.targetSize(), contentMode: .AspectFit, options: livePhotoOptions, resultHandler: {
            [unowned self] (livePhoto: PHLivePhoto?, info: [NSObject : AnyObject]?) -> Void in

            // Hide the progress view now the request has completed.
            self.progressView.hidden = true

            // Check if the request was successful.
            guard let livePhoto = livePhoto else {
                return
            }

            NSLog("Got a live photo")

            // Show the PHLivePhotoView and use it to display the requested image.
            self.showLivePhotoView()
            self.livePhotoView.livePhoto = livePhoto

            if let info = info, let isDegraded = info[PHImageResultIsDegradedKey] as? NSNumber where isDegraded.boolValue && !self.playingHint {
                // Playback a short section of the live photo; similar to the Photos share sheet.
                NSLog("playing hint...")
                self.playingHint = true
                self.livePhotoView.startPlaybackWithStyle(.Hint)
            }

            // Update the toolbar to show the correct items for a live photo.
            self.showPlaybackToolbar()
        })
    }

    func updateStaticImage() {
        guard let asset = self.asset else {
            return
        }

        // Prepare the options to pass when fetching the live photo.
        let options = PHImageRequestOptions()
        options.deliveryMode = .HighQualityFormat
        options.networkAccessAllowed = true
        options.progressHandler = { [unowned self] (progress: Double, error: NSError?, stop: UnsafeMutablePointer<ObjCBool>, info: [NSObject : AnyObject]?) in
            /*
             Progress callbacks may not be on the main thread. Since we're updating
             the UI, dispatch to the main queue.
             */
            dispatch_async(dispatch_get_main_queue()) {
                [unowned self] in
                self.progressView.progress = Float(progress)
            }
        }

        PHImageManager.defaultManager().requestImageForAsset(asset, targetSize: self.targetSize(), contentMode: .AspectFit, options: options, resultHandler: {
            [unowned self] (result: UIImage?, info: [NSObject : AnyObject]?) -> Void in
            // Hide the progress view now the request has completed.
            self.progressView.hidden = true

            // Check if the request was successful.
            guard let result = result else {
                return
            }

            // Show the UIImageView and use it to display the requested image.
            self.showStaticPhotoView()
            self.imageView.image = result
        })
    }

    // MARK: - PHPhotoLibraryChangeObserver

    func photoLibraryDidChange(changeInstance: PHChange) {
        guard let asset = self.asset else {
            return
        }

        // Call might come on any background queue. Re-dispatch to the main queue to handle it.
        dispatch_async(dispatch_get_main_queue()) { [unowned self] in
            // Check if there are changes to the asset we're displaying.
            guard let changeDetails = changeInstance.changeDetailsForObject(asset) else {
                return
            }

            // Get the updated asset.
            self.asset = changeDetails.objectAfterChanges as? PHAsset

            if self.asset != nil {
                // If the asset's content changed, update the image and stop any video playback.
                if changeDetails.assetContentChanged {
                    self.updateImage()

                    self.playerLayer?.removeFromSuperlayer()
                    self.playerLayer = nil
                }
            }
        }
    }

    // MARK: - Target Action Methods.

    @IBAction func handleEditButtonItem(sender: UIBarButtonItem) {
        guard let asset = self.asset else {
            return
        }

        // Use a UIAlertController to display the editing options to the user.
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        alertController.modalPresentationStyle = .Popover
        alertController.popoverPresentationController?.barButtonItem = sender
        alertController.popoverPresentationController?.permittedArrowDirections = .Up

        // Add an action to dismiss the UIAlertController.
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: nil))

        // If PHAsset supports edit operations, allow the user to toggle its favorite status.
        if asset.canPerformEditOperation(.Properties) {
            let favoriteActionTitle = !asset.favorite ? NSLocalizedString("Favorite", comment: "") : NSLocalizedString("Unfavorite", comment: "")

            alertController.addAction(UIAlertAction(title: favoriteActionTitle, style: .Default, handler: {
                [unowned self]
                (action: UIAlertAction) -> Void in
                self.toggleFavoriteState()
            }))
        }

        // Only allow editing if the PHAsset supports edit operations and it is not a Live Photo.
        if asset.canPerformEditOperation(.Content) && !asset.mediaSubtypes.contains(.PhotoLive) {
            // Allow filters to be applied if the PHAsset is an image.
            if asset.mediaType == .Image {
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Sepia", comment: ""), style: .Default, handler: {
                    [unowned self]
                    (action: UIAlertAction) -> Void in
                        self.applyFilterWithName("CISepiaTone")
                }))
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Chrome", comment: ""), style: .Default, handler: {
                    [unowned self]
                    (action: UIAlertAction) -> Void in
                        self.applyFilterWithName("CIPhotoEffectChrome")
                }))
            }

            // Add actions to revert any edits that have been made to the PHAsset.
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Revert", comment: ""), style: .Default, handler: {
                [unowned self]
                (action: UIAlertAction) -> Void in
                    self.revertToOriginal()
            }))
        }
        
        // Present the UIAlertController.
        self.presentViewController(alertController, animated: true, completion: nil)
    }

    @IBAction func handleTrashButtonItem(sender: AnyObject) {
        guard let asset = self.asset else {
            return
        }

        let completionHandler = {
            [unowned self] (success: Bool, error: NSError?) -> Void in
            if success {
                dispatch_async(dispatch_get_main_queue()) {
                    self.navigationController?.popViewControllerAnimated(true)
                }
            } else {
                NSLog("Error: \(error)")
            }
        }

        if let assetCollection = self.assetCollection {
            // Remove asset from album
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                if let changeRequest = PHAssetCollectionChangeRequest(forAssetCollection: assetCollection) {
                    changeRequest.removeAssets([asset])
                }
            }, completionHandler: completionHandler)
        } else {
            // Delete asset from library
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                PHAssetChangeRequest.deleteAssets([asset])
            }, completionHandler:completionHandler)
        }
    }

    @IBAction func handlePlayButtonItem(sender: AnyObject) {
        guard let asset = self.asset else {
            return
        }

        if self.livePhotoView.livePhoto != nil {
            // We're displaying a live photo, begin playing it.
            self.livePhotoView.startPlaybackWithStyle(.Full)
        } else if let playerLayer = self.playerLayer, let player = playerLayer.player {
            // An AVPlayerLayer has already been created for this asset.
            player.play()
        } else {
            // Request an AVAsset for the PHAsset we're displaying.
            let options = PHVideoRequestOptions()
            options.version = .Original
            PHImageManager.defaultManager().requestAVAssetForVideo(asset, options: options, resultHandler: {
                [unowned self]
                (avAsset: AVAsset?, audioMix: AVAudioMix?, info: [NSObject : AnyObject]?) -> Void in
                dispatch_async(dispatch_get_main_queue()) {
                    if self.playerLayer == nil {
                        guard let avAsset = avAsset else {
                            return
                        }

                        let viewLayer = self.view.layer

                        // Create an AVPlayerItem for the AVAsset.
                        let playerItem = AVPlayerItem(asset: avAsset)
                        playerItem.audioMix = audioMix

                        // Create an AVPlayer with the AVPlayerItem.
                        let player = AVPlayer(playerItem: playerItem)

                        // Create an AVPlayerLayer with the AVPlayer.
                        let playerLayer = AVPlayerLayer(player: player)

                        // Configure the AVPlayerLayer and add it to the view.
                        playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
                        playerLayer.frame = CGRectMake(0, 0, viewLayer.bounds.size.width, viewLayer.bounds.size.height)

                        viewLayer.addSublayer(playerLayer)
                        player.play()

                        // Store a reference to the player layer we added to the view.
                        self.playerLayer = playerLayer
                    }
                }
            })
        }
    }

    // MARK: - PHLivePhotoViewDelegate Protocol Methods.

    func livePhotoView(livePhotoView: PHLivePhotoView, willBeginPlaybackWithStyle playbackStyle: PHLivePhotoViewPlaybackStyle) {
        NSLog("Will Beginning Playback of Live Photo...")
    }

    func livePhotoView(livePhotoView: PHLivePhotoView, didEndPlaybackWithStyle playbackStyle: PHLivePhotoViewPlaybackStyle) {
        NSLog("Did End Playback of Live Photo...")
        self.playingHint = false

    }

    // MARK: - Photo editing methods.

    func applyFilterWithName(filterName: String) {
        guard let asset = self.asset else {
            return
        }

        // Prepare the options to pass when requesting to edit the image.
        let options = PHContentEditingInputRequestOptions()
        options.canHandleAdjustmentData = { (adjustmentData: PHAdjustmentData) -> Bool in
            return adjustmentData.formatIdentifier == AdjustmentFormatIdentifier && adjustmentData.formatVersion == "1.0"
        }

        asset.requestContentEditingInputWithOptions(options, completionHandler: {
            (contentEditingInput: PHContentEditingInput?, info: [NSObject : AnyObject]) -> Void in
            guard let contentEditingInput = contentEditingInput else {
                return
            }

            // Create a CIImage from the full image representation.
            if let url = contentEditingInput.fullSizeImageURL, var inputImage = CIImage(contentsOfURL: url) {
                inputImage = inputImage.imageByApplyingOrientation(contentEditingInput.fullSizeImageOrientation)

                // Create the filter to apply.
                if let filter = CIFilter(name: filterName) {
                    filter.setDefaults()
                    filter.setValue(inputImage, forKey: kCIInputImageKey)

                    // Apply the filter.
                    if let outputImage = filter.outputImage {
                        if let data = filterName.dataUsingEncoding(NSUTF8StringEncoding) {
                            // Create a PHAdjustmentData object that describes the filter that was applied.
                            let adjustmentData = PHAdjustmentData(formatIdentifier: AdjustmentFormatIdentifier, formatVersion: "1.0", data: data)

                            /*
                             Create a PHContentEditingOutput object and write a JPEG representation
                             of the filtered object to the renderedContentURL.
                             */
                            let contentEditingOutput = PHContentEditingOutput(contentEditingInput: contentEditingInput)

                            if let jpegData = outputImage.aapl_jpegRepresentationWithCompressionQuality(0.9) {
                                jpegData.writeToURL(contentEditingOutput.renderedContentURL, atomically: true)
                                contentEditingOutput.adjustmentData = adjustmentData

                                // Ask the shared PHPhotoLinrary to perform the changes.
                                PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                                    let request = PHAssetChangeRequest(forAsset: asset)
                                    request.contentEditingOutput = contentEditingOutput
                                }, completionHandler: { (success: Bool, error: NSError?) -> Void in
                                    if !success {
                                        NSLog("Error: \(error)")
                                    }
                                })
                            }
                        }
                    }
                }
            }
        })
    }

    func toggleFavoriteState() {
        guard let asset = self.asset else {
            return
        }

        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
            let request = PHAssetChangeRequest(forAsset: asset)
            request.favorite = !asset.favorite
        }, completionHandler: { (success: Bool, error: NSError?) -> Void in
            if !success {
                NSLog("Error: \(error)")
            }
        })
    }

    func revertToOriginal() {
        guard let asset = self.asset else {
            return
        }

        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
            let request = PHAssetChangeRequest(forAsset: asset)
            request.revertAssetContentToOriginal()
        }, completionHandler: { (success: Bool, error: NSError?) -> Void in
            if !success {
                NSLog("Error: \(error)")
            }
        })
    }
}
