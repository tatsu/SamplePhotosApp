//
//  CIImage+Convenience.swift
//  SamplePhotosApp
//
//  Created by Tatsuhiko Arai on 4/20/16.
//
//

import UIKit

extension CIImage {
    @nonobjc static var ciContext: CIContext?

    func aapl_jpegRepresentationWithCompressionQuality(compressionQuality: CGFloat) -> NSData? {
        if CIImage.ciContext == nil {
            let eaglContext = EAGLContext(API: .OpenGLES2)
            CIImage.ciContext = CIContext(EAGLContext: eaglContext)
        }
        if let outputImageRef = CIImage.ciContext?.createCGImage(self, fromRect: self.extent) {
            let uiImage = UIImage(CGImage: outputImageRef, scale: 1.0, orientation: .Up)
            // CGImageRelease(outputImageRef) isn't needed in Swift.
            return UIImageJPEGRepresentation(uiImage, compressionQuality)
        }

        return nil
    }

}