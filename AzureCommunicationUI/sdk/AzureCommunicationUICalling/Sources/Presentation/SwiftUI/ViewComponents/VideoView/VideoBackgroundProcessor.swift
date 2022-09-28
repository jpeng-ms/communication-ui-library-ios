// swiftlint:disable file_header
/*
/// Copyright (c) 2021 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.
*/
import UIKit
import Combine
import Vision
import CoreImage.CIFilterBuiltins

@available(iOS 15.0, *)
class VideoBackgroundProcessor {
    static let shared = VideoBackgroundProcessor()
    @Published var photoOutput = UIImage()
    let context = CIContext()
    let request = VNGeneratePersonSegmentationRequest()

    func blendImages(background: CIImage,
                     foreground: CIImage,
                     mask: CIImage,
                     isRedMask: Bool = false) -> CIImage? {
        // scale mask
        let maskScaleX = foreground.extent.width / mask.extent.width
        let maskScaleY = foreground.extent.height / mask.extent.height
        let maskScaled = mask.transformed(by: __CGAffineTransformMake(maskScaleX, 0, 0, maskScaleY, 0, 0))

        // scale background
        let backgroundScaleX = (foreground.extent.width / background.extent.width)
        let backgroundScaleY = (foreground.extent.height / background.extent.height)
        let backgroundScaled = background.transformed(by:
                                                        __CGAffineTransformMake(backgroundScaleX,
                                                                                0,
                                                                                0,
                                                                                backgroundScaleY,
                                                                                0,
                                                                                0))

        let blendFilter = isRedMask ? CIFilter.blendWithRedMask() : CIFilter.blendWithMask()
        blendFilter.inputImage = foreground
        blendFilter.backgroundImage = backgroundScaled
        blendFilter.maskImage = maskScaled

        return blendFilter.outputImage
    }

    private func renderAsUIImage(_ image: CIImage) -> UIImage? {
        guard let cgImage = context.createCGImage(image, from: image.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    func processVideoFrame( foreground: CVPixelBuffer,
                            background: CGImage) -> CIImage? {
            // Create request handler
        let ciForeground = CIImage(cvPixelBuffer: foreground)
        let personSegmentFilter = CIFilter.personSegmentation()
        personSegmentFilter.inputImage = ciForeground
        if let mask = personSegmentFilter.outputImage {
            guard let output = blendImages(
                background: CIImage(cgImage: background),
                foreground: ciForeground,
                mask: mask,
                isRedMask: true) else {
                print("Error blending images")
                return nil
            }
            return output
        }
        return nil
    }
}

struct Background {
    var backgroundImage: UIImage
    var foregroundImage: UIImage
}
