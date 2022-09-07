//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import AzureCommunicationCalling
import Foundation

public enum CameraDevice {
    case front
    case back
}

public protocol CallingSDKWrapperProtocol {
    func getRemoteParticipant(_ identifier: String) -> RemoteParticipant?
    func getLocalVideoStream(_ identifier: String) -> LocalVideoStream?

    func startPreviewVideoStream() async throws -> String
    func setupCall() async throws
    func startCall(isCameraPreferred: Bool, isAudioPreferred: Bool) async throws
    func endCall() async throws
    func startCallLocalVideoStream() async throws -> String
    func stopLocalVideoStream() async throws
    func switchCamera() async throws -> CameraDevice
    func muteLocalMic() async throws
    func unmuteLocalMic() async throws
    func holdCall() async throws
    func resumeCall() async throws

    var callingEventsHandler: CallingSDKEventsHandling { get }
}

open class SDKWrapperBuilder {
    public init() {}

    open func build() -> CallingSDKWrapperProtocol {
        fatalError("You must override this method in your implementation")
    }
}
