//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import AzureCommunicationCalling
import Foundation
@testable import AzureCommunicationUICalling

class CallingSDKEventsHandlerMocking: NSObject, CallingSDKEventsHandling {
    var participantsInfoList: AsyncStream<[ParticipantInfoModel]>!
    var callInfo: AsyncStream<CallInfoModel>!
    var isRecordingActive: AsyncStream<Bool>!
    var isTranscriptionActive: AsyncStream<Bool>!
    var isLocalUserMuted: AsyncStream<Bool>!

    func assign(_ recordingCallFeature: RecordingCallFeature) {}

    func assign(_ transcriptionCallFeature: TranscriptionCallFeature) {}

    func setupProperties() {}
}
