//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation
import AzureCommunicationCalling
@testable import AzureCommunicationUICalling

class CallingSDKWrapperMocking: CallingSDKWrapperProtocol {
    var error: NSError?
    var callingEventsHandler: CallingSDKEventsHandling = CallingSDKEventsHandler(logger: LoggerMocking())

    func getLocalVideoStream(_ identifier: String) -> LocalVideoStream? {
        return nil
    }

    func startCallLocalVideoStream() async throws -> String {
        return ""
    }

    func stopLocalVideoStream() async throws { }

    func switchCamera() async throws -> CameraDevice {
        switchCameraCallCount += 1
        return .front
    }

    var setupCallCallCount: Int = 0
    var startCallCallCount: Int = 0
    var endCallCallCount: Int = 0
    var switchCameraCallCount: Int = 0
    var getRemoteParticipantCallIds: [String] = []

    var holdCallCalled: Bool = false
    var resumeCallCalled: Bool = false
    var muteLocalMicCalled: Bool = false
    var unmuteLocalMicCalled: Bool = false
    var startPreviewVideoStreamCalled: Bool = false

    var isMuted: Bool?
    var isCameraPreferred: Bool?
    var isAudioPreferred: Bool?

    // SHOW BUG HERE!
//    func muteLocalMic() -> AnyPublisher<Void, Error> {
//        muteLocalMicCalled = true
//        isMuted = true
//        return Future<Void, Error> { promise in
//            if let error = self.error {
//                return promise(.failure(error))
//            }
//            return promise(.success(()))
//        }.eraseToAnyPublisher()
//    }
    func muteLocalMic() async throws {
        muteLocalMicCalled = true
        if let error = self.error {
            throw error
        }
        isMuted = true
    }

//    func unmuteLocalMic() -> AnyPublisher<Void, Error> {
//        unmuteLocalMicCalled = true
//        isMuted = false
//        return Future<Void, Error> { promise in
//            if let error = self.error {
//                return promise(.failure(error))
//            }
//            return promise(.success(()))
//        }.eraseToAnyPublisher()
//    }
    func unmuteLocalMic() async throws {
        unmuteLocalMicCalled = true
        if let error = self.error {
            throw error
        }
        isMuted = false
    }

    func getRemoteParticipant(_ identifier: String) -> RemoteParticipant? {
        getRemoteParticipantCallIds.append(identifier)
        return nil
    }

    func startPreviewVideoStream() async throws -> String {
        startPreviewVideoStreamCalled = true
        return ""
    }

    func setupCall() async throws {
        setupCallCallCount += 1
    }

    func setupCallWasCalled() -> Bool {
        return setupCallCallCount > 0
    }

    func startCall(isCameraPreferred: Bool, isAudioPreferred: Bool) async throws {
        startCallCallCount += 1
        self.isCameraPreferred = isCameraPreferred
        self.isAudioPreferred = isAudioPreferred
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

    func startCallWasCalled() -> Bool {
        return startCallCallCount > 0
    }

    func endCall() async throws {
        endCallCallCount += 1
    }

    func endCallWasCalled() -> Bool {
        return endCallCallCount > 0
    }

    func muteWasCalled() -> Bool {
        return muteLocalMicCalled
    }

    func unmuteWasCalled() -> Bool {
        return unmuteLocalMicCalled
    }

    func videoEnabledWhenJoinCall() -> Bool {
        return isCameraPreferred ?? false
    }

    func mutedWhenJoinCall() -> Bool {
        return !(isAudioPreferred ?? false)
    }

    func switchCameraWasCalled() -> Bool {
        return switchCameraCallCount > 0
    }

}
