//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation
import AzureCommunicationCalling
import AVFoundation
import MetalKit

struct RemoteParticipantVideoViewId {
    let userIdentifier: String
    let videoStreamIdentifier: String
}

struct ParticipantRendererViewInfo {
    let rendererView: UIView
    let streamSize: CGSize
}

protocol RendererViewManager: AnyObject {
    var didRenderFirstFrame: ((CGSize) -> Void)? { get set }

    func getRemoteParticipantVideoRendererView
    (_ videoViewId: RemoteParticipantVideoViewId) -> ParticipantRendererViewInfo?
    func getRemoteParticipantVideoRendererViewSize() -> CGSize?
}

class VideoViewManager: NSObject, RendererDelegate, RendererViewManager {

    struct VideoStreamCache {
        var renderer: VideoStreamRenderer
        var rendererView: RendererView
        var mediaStreamType: MediaStreamType
    }
    private let logger: Logger
    private var displayedRemoteParticipantsRendererView = MappedSequence<String, VideoStreamCache>()

    private var localRendererViews = MappedSequence<String, VideoStreamCache>()

    private let callingSDKWrapper: CallingSDKWrapperProtocol

    let session = AVCaptureSession()
    var prevLayer: AVCaptureVideoPreviewLayer?
    var videoOutput = AVCaptureVideoDataOutput()
    let cameraView = MTKView()
    var metalDevice: MTLDevice?
    var metalCommandQueue: MTLCommandQueue?
    var ciContext: CIContext?
    var background: UIImage?
    var currentCIImage: CIImage? {
      didSet {
        cameraView.draw()
      }
    }

    init(callingSDKWrapper: CallingSDKWrapperProtocol,
         logger: Logger) {
        self.callingSDKWrapper = callingSDKWrapper
        self.logger = logger
    }

    deinit {
        disposeViews()
    }

    func updateDisplayedRemoteVideoStream(_ videoViewIdArray: [RemoteParticipantVideoViewId]) {
        let displayedKeys = videoViewIdArray.map {
            return generateCacheKey(userIdentifier: $0.userIdentifier, videoStreamId: $0.videoStreamIdentifier)
        }

        displayedRemoteParticipantsRendererView.makeKeyIterator().forEach { [weak self] key in
            if !displayedKeys.contains(key) {
                self?.disposeRemoteParticipantVideoRendererView(key)
            }
        }
    }

    func updateDisplayedLocalVideoStream(_ identifier: String?) {
        if identifier == nil {
            DispatchQueue(label: "video").async {
                self.session.stopRunning()
            }
        }
        localRendererViews.makeKeyIterator().forEach { [weak self] key in
            if identifier != key {
                self?.disposeLocalVideoRendererCache(key)
            }
        }
    }

    func getLocalVideoRendererView(_ videoStreamId: String) -> UIView? {
        return getLocalVideoNativeSteam()
        if let localRenderCache = localRendererViews.value(forKey: videoStreamId) {
            return localRenderCache.rendererView
        }

        guard let videoStream = callingSDKWrapper.getLocalVideoStream(videoStreamId) else {
            return nil
        }

        do {
            let newRenderer: VideoStreamRenderer = try VideoStreamRenderer(localVideoStream: videoStream)
            let newRendererView: RendererView = try newRenderer.createView(
                withOptions: CreateViewOptions(scalingMode: .crop))
            let cache = VideoStreamCache(renderer: newRenderer,
                                         rendererView: newRendererView,
                                         mediaStreamType: videoStream.mediaStreamType)
            localRendererViews.append(forKey: videoStreamId,
                                      value: cache)
            return newRendererView
        } catch let error {
            logger.error("Failed to render remote video, reason:\(error.localizedDescription)")
            return nil
        }

    }

    // MARK: ParticipantRendererViewManager

    var didRenderFirstFrame: ((CGSize) -> Void)?

    func getRemoteParticipantVideoRendererView(_ videoViewId: RemoteParticipantVideoViewId)
                                                                -> ParticipantRendererViewInfo? {
        let videoStreamId = videoViewId.videoStreamIdentifier
        let userIdentifier = videoViewId.userIdentifier
        let cacheKey = generateCacheKey(userIdentifier: videoViewId.userIdentifier,
                                        videoStreamId: videoStreamId)
        if let videoStreamCache = displayedRemoteParticipantsRendererView.value(forKey: cacheKey) {
            let streamSize = CGSize(width: Int(videoStreamCache.renderer.size.width),
                              height: Int(videoStreamCache.renderer.size.height))
            return ParticipantRendererViewInfo(rendererView: videoStreamCache.rendererView,
                                               streamSize: streamSize)
        }

        guard let participant = callingSDKWrapper.getRemoteParticipant(userIdentifier),
              let videoStream = participant.videoStreams.first(where: { stream in
                  return String(stream.id) == videoStreamId
              }) else {
            return nil
        }

        do {
            let options = CreateViewOptions(scalingMode: videoStream.mediaStreamType == .screenSharing ? .fit : .crop)
            let newRenderer: VideoStreamRenderer = try VideoStreamRenderer(remoteVideoStream: videoStream)
            let newRendererView: RendererView = try newRenderer.createView(withOptions: options)

            let cache = VideoStreamCache(renderer: newRenderer,
                                         rendererView: newRendererView,
                                         mediaStreamType: videoStream.mediaStreamType)
            displayedRemoteParticipantsRendererView.append(forKey: cacheKey,
                                                           value: cache)

            if videoStream.mediaStreamType == .screenSharing {
                newRenderer.delegate = self
            }

            return ParticipantRendererViewInfo(rendererView: newRendererView, streamSize: .zero)
        } catch let error {
            logger.error("Failed to render remote video, reason:\(error.localizedDescription)")
            return nil
        }
    }

    func getRemoteParticipantVideoRendererViewSize() -> CGSize? {
        if let screenShare = displayedRemoteParticipantsRendererView.first(where: { cache in
            cache.mediaStreamType == .screenSharing
        }) {
            return CGSize(width: Int(screenShare.renderer.size.width), height: Int(screenShare.renderer.size.height))
        }

        return nil
    }

    // MARK: Helper functions

    private func disposeViews() {
        displayedRemoteParticipantsRendererView.makeKeyIterator().forEach { key in
            self.disposeRemoteParticipantVideoRendererView(key)
        }
        localRendererViews.makeKeyIterator().forEach { key in
            self.disposeLocalVideoRendererCache(key)
        }
    }

    private func disposeRemoteParticipantVideoRendererView(_ cacheId: String) {
        if let renderer = displayedRemoteParticipantsRendererView.removeValue(forKey: cacheId) {
            renderer.renderer.dispose()
            renderer.renderer.delegate = nil
        }
    }

    private func disposeLocalVideoRendererCache(_ identifier: String) {
        if let renderer = localRendererViews.removeValue(forKey: identifier) {
            renderer.renderer.dispose()
        }
    }

    private func generateCacheKey(userIdentifier: String, videoStreamId: String) -> String {
        return ("\(userIdentifier):\(videoStreamId)")
    }

    // MARK: RendererDelegate

    func videoStreamRenderer(didRenderFirstFrame renderer: VideoStreamRenderer) {
        let size = CGSize(width: Int(renderer.size.width), height: Int(renderer.size.height))
        didRenderFirstFrame?(size)
    }

    func videoStreamRenderer(didFailToStart renderer: VideoStreamRenderer) {
        logger.error("Failed to render remote screenshare video. \(renderer)")
    }
}

// MARK: virtual background spike
// Reference:
/*
-   https://developer.apple.com/documentation/avfoundation/additional_data_capture/
    avcamfilter_applying_filters_to_a_capture_stream#/apple_ref/doc/uid/TP40017556
-   https://www.willowtreeapps.com/craft/how-to-apply-a-filter-to-a-video-stream-in-ios
-   https://rockyshikoku.medium.com/people-cut-out-on-ios-virtual-background-background-blur-composite-76ac981ee56c
-   https://www.raywenderlich.com/29650263-person-segmentation-in-the-vision-framework#toc-anchor-007
*/
extension VideoViewManager {
    func getLocalVideoNativeSteam() -> UIView? {
        setupMetal()
        setupCoreImage()
        // Free to use under the Unsplash License
        // https://unsplash.com/photos/rRiAzFkJPMo
        // https://unsplash.com/photos/wawEfYdpkag
        // Image Authors: Yann Maignan, Austin Distel
        background = UIImage(named: "austin-distel-wawEfYdpkag-unsplash",
                             in: Bundle(for: CallComposite.self),
                             compatibleWith: nil)
        let baseView = UIView()
        baseView.frame = CGRect(x: 0, y: 0, width: 500, height: 900)
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .front) else {
            return baseView
        }
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            return baseView
        }
        session.addInput(input)
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            session.beginConfiguration()
            videoOutput.setSampleBufferDelegate(self, queue: .main)
            videoOutput.alwaysDiscardsLateVideoFrames = true
            session.addOutput(self.videoOutput)
            videoOutput.connections.first?.videoOrientation = .portrait
            videoOutput.connections.first?.isVideoMirrored = true
            session.commitConfiguration()
        default:
           break
       }
        baseView.addSubview(cameraView)
        DispatchQueue(label: "video").async {
            self.session.startRunning()
        }
        return baseView
    }

    func setupMetal() {
        metalDevice = MTLCreateSystemDefaultDevice()
        guard let device = metalDevice else {
            return
        }
        metalCommandQueue = device.makeCommandQueue()
        cameraView.frame = CGRect(x: 0, y: 0, width: 500, height: 900)
        cameraView.device = device
        cameraView.isPaused = true
        cameraView.enableSetNeedsDisplay = false
        cameraView.delegate = self
        cameraView.framebufferOnly = false
    }

    func setupCoreImage() {
        guard let device = metalDevice else {
          return
        }
        ciContext = CIContext(mtlDevice: device)
    }
}

extension VideoViewManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
      // Grab the pixelbuffer frame from the camera output
      guard let pixelBuffer = sampleBuffer.imageBuffer else {
        return
      }

      let foreground = CIImage(cvPixelBuffer: pixelBuffer)
      let backgroundImg = blurredImage(with: foreground)
      DispatchQueue.global().async {
          if #available(iOS 15.0, *) {
              if let output = VideoBackgroundProcessor.shared.processVideoFrame(
                foreground: pixelBuffer,
                background: backgroundImg) {
                  DispatchQueue.main.async {
                      self.currentCIImage = output
                  }
              }
          }
      }
    }
    func blurredImage(with inputImage: CIImage) -> CIImage {
        let context = CIContext(options: nil)
        //  Setting up Gaussian Blur
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(inputImage, forKey: kCIInputImageKey)
        filter?.setValue(50.0, forKey: "inputRadius")
        let result = filter?.value(forKey: kCIOutputImageKey) as? CIImage

       /*  CIGaussianBlur has a tendency to shrink the image a little, this ensures it matches
        *  up exactly to the bounds of our original image */

        let cgImage = context.createCGImage(result ?? CIImage(), from: inputImage.extent)
        let retVal = CIImage(cgImage: cgImage!)
        return retVal
    }
  }

extension VideoViewManager: MTKViewDelegate {
    func draw(in view: MTKView) {
      guard let commandBuffer = metalCommandQueue?.makeCommandBuffer(),
        let ciImage = currentCIImage,
        let currentDrawable = view.currentDrawable else {
        return
      }

      let drawSize = cameraView.drawableSize
      let scaleX = drawSize.width / ciImage.extent.width
      let scaleY = drawSize.height / ciImage.extent.height

      let newImage = ciImage.transformed(by: .init(scaleX: scaleX, y: scaleY))
      // render into the metal texture
      self.ciContext?.render( newImage,
                              to: currentDrawable.texture,
                              commandBuffer: commandBuffer,
                              bounds: newImage.extent,
                              colorSpace: CGColorSpaceCreateDeviceRGB())
      // register drawable to command buffer
      commandBuffer.present(currentDrawable)
      commandBuffer.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}
