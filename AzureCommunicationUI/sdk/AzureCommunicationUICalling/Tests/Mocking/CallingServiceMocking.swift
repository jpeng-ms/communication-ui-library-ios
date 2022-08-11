//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation
@testable import AzureCommunicationUICalling

class CallingServiceMocking: CallingServiceProtocol {
    var error: Error?
    var videoStreamId: String?
    var cameraDevice: CameraDevice = .front
    var setupCallCalled: Bool = false
    var startCallCalled: Bool = false
    var endCallCalled: Bool = false
    var holdCallCalled: Bool = false
    var resumeCallCalled: Bool = false

    var localCameraStream: String = "MockCameraStream"

    var startLocalVideoStreamCalled: Bool = false
    var stopLocalVideoStreamCalled: Bool = false
    var switchCameraCalled: Bool = false

    var muteLocalMicCalled: Bool = false
    var unmuteLocalMicCalled: Bool = false

    func startLocalVideoStream() async throws -> String {
        startLocalVideoStreamCalled = true

        if let error = self.error {
            throw error
        }

        return videoStreamId ?? ""
    }

    func stopLocalVideoStream() async throws {
        stopLocalVideoStreamCalled = true
        if let error = self.error {
            throw error
        }
    }

    func switchCamera() async throws -> CameraDevice {
        switchCameraCalled = true

        if let error = self.error {
            throw error
        }
        return cameraDevice
    }

    func muteLocalMic() async throws {
        muteLocalMicCalled = true
        if let error = self.error {
            throw error
        }
    }

    func unmuteLocalMic() async throws {
        unmuteLocalMicCalled = true
        if let error = self.error {
            throw error
        }
    }

    var participantsInfoListStream: AsyncStream<[ParticipantInfoModel]> = AsyncStream<[ParticipantInfoModel]> { _ in }
    var callInfoStream: AsyncStream<CallInfoModel> = AsyncStream<CallInfoModel> { _ in }
    var isRecordingActiveEvents: AsyncStream<Bool> = AsyncStream<Bool> { _ in }
    var isTranscriptionActiveEvents: AsyncStream<Bool> = AsyncStream<Bool> { _ in }
    var isLocalUserMutedEvents: AsyncStream<Bool> = AsyncStream<Bool> { _ in }

    func setupCall() async throws {
        setupCallCalled = true
        if let error = self.error {
            throw error
        }
    }

    func startCall(isCameraPreferred: Bool, isAudioPreferred: Bool) async throws {
        startCallCalled = true
        if let error = self.error {
            throw error
        }

    }

    func endCall() async throws {
        endCallCalled = true
        if let error = self.error {
            throw error
        }
    }

    func requestCameraPreviewOn() async throws -> String {
        if let error = self.error {
            throw error
        }
        return self.localCameraStream
    }

    func holdCall() async throws {
        holdCallCalled = true
        if let error = self.error {
            throw error
        }
    }

    func resumeCall() async throws {
        resumeCallCalled = true
        if let error = self.error {
            throw error
        }
    }
}
