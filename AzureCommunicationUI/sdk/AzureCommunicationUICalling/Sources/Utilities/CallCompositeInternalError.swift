//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation

enum CallCompositeInternalError: String, Error, Equatable {
    case callTokenFailed
    case callAgentFailed
    case callJoinFailed
    case callEndFailed
    case callHoldFailed
    case callResumeFailed
    case callEvicted
    case callDenied
    case cameraSwitchFailed
    case cameraOnFailed

    func toCallCompositeErrorCode() -> String? {
        switch self {
        case .callTokenFailed:
            return CallCompositeErrorCode.tokenExpired
        case .callAgentFailed:
            return ""
        case .callJoinFailed:
            return CallCompositeErrorCode.callJoin
        case .callEndFailed:
            return CallCompositeErrorCode.callEnd
        case .callHoldFailed,
                .callResumeFailed,
                .callEvicted,
                .callDenied,
                .cameraSwitchFailed,
                .cameraOnFailed:
            return nil
        }
    }

    func isFatalError() -> Bool {
        switch self {
        case .callTokenFailed,
                .callAgentFailed,
                .callJoinFailed,
                .callEndFailed:
            return true
        case .callHoldFailed,
                .callResumeFailed,
                .callEvicted,
                .callDenied,
                .cameraSwitchFailed,
                .cameraOnFailed:
            return false
        }
    }
}
