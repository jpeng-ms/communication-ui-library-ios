//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation

protocol CallingMiddlewareHandling {
    func setupCall(state: AppState, dispatch: @escaping ActionDispatch)
    func startCall(state: AppState, dispatch: @escaping ActionDispatch)
    func endCall(state: AppState, dispatch: @escaping ActionDispatch)
    func holdCall(state: AppState, dispatch: @escaping ActionDispatch)
    func resumeCall(state: AppState, dispatch: @escaping ActionDispatch)
    func enterBackground(state: AppState, dispatch: @escaping ActionDispatch)
    func enterForeground(state: AppState, dispatch: @escaping ActionDispatch)
    func audioSessionInterrupted(state: AppState, dispatch: @escaping ActionDispatch)
    func requestCameraPreviewOn(state: AppState, dispatch: @escaping ActionDispatch)
    func requestCameraOn(state: AppState, dispatch: @escaping ActionDispatch)
    func requestCameraOff(state: AppState, dispatch: @escaping ActionDispatch)
    func requestCameraSwitch(state: AppState, dispatch: @escaping ActionDispatch)
    func requestMicrophoneMute(state: AppState, dispatch: @escaping ActionDispatch)
    func requestMicrophoneUnmute(state: AppState, dispatch: @escaping ActionDispatch)
    func onCameraPermissionIsSet(state: AppState, dispatch: @escaping ActionDispatch)
}

class CallingMiddlewareHandler: CallingMiddlewareHandling {
    private let callingService: CallingServiceProtocol
    private let logger: Logger
    private var subscriptionTasks = [Task<Void, Never>]()

    init(callingService: CallingServiceProtocol, logger: Logger) {
        self.callingService = callingService
        self.logger = logger
    }

    func setupCall(state: AppState, dispatch: @escaping ActionDispatch) {
        Task {
            do {
                try await callingService.setupCall()
                if state.permissionState.cameraPermission == .granted,
                   state.localUserState.cameraState.operation == .off,
                   state.errorState.internalError == nil {
                    dispatch(.localUserAction(.cameraPreviewOnTriggered))
                }
            } catch {
                handle(error: error, errorType: .callJoinFailed, dispatch: dispatch)
            }
        }
    }

    func startCall(state: AppState, dispatch: @escaping ActionDispatch) {
        Task {
            do {
                try await callingService.startCall(
                    isCameraPreferred: state.localUserState.cameraState.operation == .on,
                    isAudioPreferred: state.localUserState.audioState.operation == .on
                )
                subscription(dispatch: dispatch)
            } catch {
                handle(error: error, errorType: .callJoinFailed, dispatch: dispatch)
            }
        }
    }

    func endCall(state: AppState, dispatch: @escaping ActionDispatch) {
        Task {
            do {
                try await callingService.endCall()
            } catch {
                handle(error: error, errorType: .callEndFailed, dispatch: dispatch)
            }
        }
    }

    func holdCall(state: AppState, dispatch: @escaping ActionDispatch) {
        guard state.callingState.status == .connected else {
            return
        }

        Task {
            do {
                try await callingService.holdCall()
            } catch {
                handle(error: error, errorType: .callHoldFailed, dispatch: dispatch)
            }
        }
    }

    func resumeCall(state: AppState, dispatch: @escaping ActionDispatch) {
        guard state.callingState.status == .localHold else {
            return
        }

        Task {
            do {
                try await callingService.resumeCall()
            } catch {
                handle(error: error, errorType: .callResumeFailed, dispatch: dispatch)
            }
        }
    }

    func enterBackground(state: AppState, dispatch: @escaping ActionDispatch) {
        guard state.callingState.status == .connected,
              state.localUserState.cameraState.operation == .on else {
            return
        }

        Task {
            do {
                try await callingService.stopLocalVideoStream()
            } catch {
                dispatch(.localUserAction(.cameraPausedFailed(error: error)))
            }
        }
    }

    func enterForeground(state: AppState, dispatch: @escaping ActionDispatch) {
        guard state.callingState.status == .connected || state.callingState.status == .localHold,
              state.localUserState.cameraState.operation == .paused else {
            return
        }
        requestCameraOn(state: state, dispatch: dispatch)
    }

    func requestCameraPreviewOn(state: AppState, dispatch: @escaping ActionDispatch) {
        if state.permissionState.cameraPermission == .notAsked {
            dispatch(.permissionAction(.cameraPermissionRequested))
        } else {
            Task {
                do {
                    let identifier = try await callingService.requestCameraPreviewOn()
                    dispatch(.localUserAction(.cameraOnSucceeded(videoStreamIdentifier: identifier)))
                } catch {
                    dispatch(.localUserAction(.cameraOnFailed(error: error)))
                }
            }
        }
    }

    func requestCameraOn(state: AppState, dispatch: @escaping ActionDispatch) {
        if state.permissionState.cameraPermission == .notAsked {
            dispatch(.permissionAction(.cameraPermissionRequested))
        } else {
            Task {
                do {
                    let streamId = try await callingService.startLocalVideoStream()
                    try await Task.sleep(nanoseconds: NSEC_PER_SEC)
                    dispatch(.localUserAction(.cameraOnSucceeded(videoStreamIdentifier: streamId)))
                } catch {
                    dispatch(.localUserAction(.cameraOnFailed(error: error)))
                }
            }
        }
    }

    func requestCameraOff(state: AppState, dispatch: @escaping ActionDispatch) {
        Task {
            do {
                try await callingService.stopLocalVideoStream()
                dispatch(.localUserAction(.cameraOffSucceeded))
            } catch {
                dispatch(.localUserAction(.cameraOffFailed(error: error)))
            }
        }
    }

    func requestCameraSwitch(state: AppState, dispatch: @escaping ActionDispatch) {
        Task {
            do {
                let device = try await callingService.switchCamera()
                try await Task.sleep(nanoseconds: NSEC_PER_SEC)
                dispatch(.localUserAction(.cameraSwitchSucceeded(cameraDevice: device)))
            } catch {
                dispatch(.localUserAction(.cameraSwitchFailed(error: error)) )
            }
        }
    }

    func requestMicrophoneMute(state: AppState, dispatch: @escaping ActionDispatch) {
        Task {
            do {
                try await callingService.muteLocalMic()
            } catch {
                dispatch(.localUserAction(.microphoneOffFailed(error: error)))
            }
        }
    }

    func requestMicrophoneUnmute(state: AppState, dispatch: @escaping ActionDispatch) {
        Task {
            do {
                try await callingService.unmuteLocalMic()
            } catch {
                dispatch(.localUserAction(.microphoneOnFailed(error: error)))
            }
        }
    }

    func onCameraPermissionIsSet(state: AppState, dispatch: @escaping ActionDispatch) {
        guard state.permissionState.cameraPermission == .requesting else {
            return
        }

        switch state.localUserState.cameraState.transmission {
        case .local:
            dispatch(.localUserAction(.cameraPreviewOnTriggered))
        case .remote:
            dispatch(.localUserAction(.cameraOnTriggered))
        }
    }

    func audioSessionInterrupted(state: AppState, dispatch: @escaping ActionDispatch) {
        guard state.callingState.status == .connected else {
            return
        }

        dispatch(.callingAction(.holdRequested))
    }
}

extension CallingMiddlewareHandler {
    private func cancelSubscriptions() {
        for task in subscriptionTasks {
            task.cancel()
        }
        subscriptionTasks.removeAll()
    }

    private func subscription(dispatch: @escaping ActionDispatch) {
        logger.debug("Subscribe to calling service subjects")

        subscriptionTasks.append(
            Task {
                for await participantinfo in callingService.participantsInfoListStream {
                    dispatch(.callingAction(.participantListUpdated(participants: participantinfo)))
                }
            }
        )
//        callingService.participantsInfoListSubject
//            .throttle(for: 1.25, scheduler: DispatchQueue.main, latest: true)
//            .sink { list in
//                dispatch(.callingAction(.participantListUpdated(participants: list)))
//            }.store(in: subscription)

        subscriptionTasks.append(
            Task { [unowned self] in
                for await callInfoModel in callingService.callInfoStream {
                    let internalError = callInfoModel.internalError
                    let callingStatus = callInfoModel.status

                    self.handle(callingStatus: callingStatus, dispatch: dispatch)
                    self.logger.debug("Dispatch State Update: \(callingStatus)")

                    if let internalError = internalError {
                        self.handleCallInfo(internalError: internalError,
                                            dispatch: dispatch) {
                            self.logger.debug("Subscription cancelled with Error Code: \(internalError)")
                            self.cancelSubscriptions()
                        }
                        // to fix the bug that resume call won't work without Internet
                        // we exit the UI library when we receive the wrong status .remoteHold
                    } else if callingStatus == .disconnected || callingStatus == .remoteHold {
                        self.logger.debug("Subscription cancel happy path")
                        dispatch(.compositeExitAction)
                        self.cancelSubscriptions()
                    }
                }
            }
        )

        subscriptionTasks.append(
            Task {
                for await isRecordingActive in callingService.isRecordingActiveEvents {
                    dispatch(.callingAction(.recordingStateUpdated(isRecordingActive: isRecordingActive)))
                }
            }
        )

        subscriptionTasks.append(
            Task {
                for await isTranscriptionActive in callingService.isTranscriptionActiveEvents {
                    dispatch(.callingAction(.transcriptionStateUpdated(isTranscriptionActive: isTranscriptionActive)))
                }
            }
        )

        subscriptionTasks.append(
            Task {
                for await isLocalUserMuted in callingService.isLocalUserMutedEvents {
                    dispatch(.localUserAction(.microphoneMuteStateUpdated(isMuted: isLocalUserMuted)))
                }
            }
        )
    }
}
