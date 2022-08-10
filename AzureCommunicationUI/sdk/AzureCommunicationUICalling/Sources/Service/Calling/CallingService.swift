//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation

protocol CallingServiceProtocol {
    var participantsInfoListStream: AsyncStream<[ParticipantInfoModel]> { get }
    var callInfoStream: AsyncStream<CallInfoModel> { get }

    var isRecordingActiveEvents: AsyncStream<Bool> { get }
    var isTranscriptionActiveEvents: AsyncStream<Bool> { get }
    var isLocalUserMutedEvents: AsyncStream<Bool> { get }

    func setupCall() async throws
    func startCall(isCameraPreferred: Bool, isAudioPreferred: Bool) async throws
    func endCall() async throws

    func requestCameraPreviewOn() async throws -> String
    func startLocalVideoStream() async throws -> String
    func stopLocalVideoStream() async throws
    func switchCamera() async throws -> CameraDevice

    func muteLocalMic() async throws
    func unmuteLocalMic() async throws

    func holdCall() async throws
    func resumeCall() async throws
}

class CallingService: NSObject, CallingServiceProtocol {

    private let logger: Logger
    private let callingSDKWrapper: CallingSDKWrapperProtocol

    var participantsInfoListStream: AsyncStream<[ParticipantInfoModel]>
    var callInfoStream: AsyncStream<CallInfoModel>
    var isRecordingActiveEvents: AsyncStream<Bool>
    var isTranscriptionActiveEvents: AsyncStream<Bool>
    var isLocalUserMutedEvents: AsyncStream<Bool>

    init(logger: Logger,
         callingSDKWrapper: CallingSDKWrapperProtocol ) {
        self.logger = logger
        self.callingSDKWrapper = callingSDKWrapper

        participantsInfoListStream = callingSDKWrapper.callingEventsHandler.participantsInfoList
        callInfoStream = callingSDKWrapper.callingEventsHandler.callInfo
        isRecordingActiveEvents = callingSDKWrapper.callingEventsHandler.isRecordingActive
        isTranscriptionActiveEvents = callingSDKWrapper.callingEventsHandler.isTranscriptionActive
        isLocalUserMutedEvents = callingSDKWrapper.callingEventsHandler.isLocalUserMuted
    }

    func setupCall() async throws {
        try await callingSDKWrapper.setupCall()
    }

    func startCall(isCameraPreferred: Bool, isAudioPreferred: Bool) async throws {
        try await callingSDKWrapper.startCall(
            isCameraPreferred: isCameraPreferred,
            isAudioPreferred: isAudioPreferred
        )
    }

    func endCall() async throws {
       try await callingSDKWrapper.endCall()
    }

    func requestCameraPreviewOn() async throws -> String {
        return try await callingSDKWrapper.startPreviewVideoStream()
    }

    func startLocalVideoStream() async throws -> String {
        return try await callingSDKWrapper.startCallLocalVideoStream()
    }

    func stopLocalVideoStream() async throws {
        try await callingSDKWrapper.stopLocalVideoStream()
    }

    func switchCamera() async throws -> CameraDevice {
        try await callingSDKWrapper.switchCamera()
    }

    func muteLocalMic() async throws {
        try await callingSDKWrapper.muteLocalMic()
    }

    func unmuteLocalMic() async throws {
        try await callingSDKWrapper.unmuteLocalMic()
    }

    func holdCall() async throws {
        try await callingSDKWrapper.holdCall()
    }

    func resumeCall() async throws {
        try await callingSDKWrapper.resumeCall()
    }
}
