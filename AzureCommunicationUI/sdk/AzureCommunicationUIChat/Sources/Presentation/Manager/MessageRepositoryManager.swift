//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation
import AzureCore

protocol MessageRepositoryManagerProtocol {
    var messages: [ChatMessageInfoModel] { get }
    var localParticipantLastRead: Date { get }
    var remoteParticipantEarliestRead: Date { get }

    // local event
    func addInitialMessages(initialMessages: [ChatMessageInfoModel])
    func addPreviousMessages(previousMessages: [ChatMessageInfoModel])
    // dummy message
    func addNewSendMessage(message: ChatMessageInfoModel)
    func updateNewSendMessageId(newMessage: ChatMessageInfoModel)

    // receiving events
    func addReceivedMessage(message: ChatMessageInfoModel)
    func replaceEditedMessage(message: ChatMessageInfoModel)
    func removeDeletedMessage(message: ChatMessageInfoModel)
    func replaceSendMessageRetry(message: ChatMessageInfoModel)
    func addTopicSystemMessage(newTopic: String)
    func addParticipantsAddedSystemMessage(participants: [ParticipantInfoModel])
    func addParticipantsRemovedSystemMessage(participants: [ParticipantInfoModel])

    // read receipt
    func updateLocalParticipantLastRead(timestamp: Date)
    func updateRemoteParticipantEarliestRead(timestamp: Date)
}

class MessageRepositoryManager: MessageRepositoryManagerProtocol {
    var messages: [ChatMessageInfoModel] = []
    var localParticipantLastRead = Date()
    var remoteParticipantEarliestRead = Date()

    private let eventsHandler: ChatComposite.Events

    init(chatCompositeEventsHandler: ChatComposite.Events) {
        self.eventsHandler = chatCompositeEventsHandler
    }

    func addInitialMessages(initialMessages: [ChatMessageInfoModel]) {
        messages = initialMessages
    }

    func addPreviousMessages(previousMessages: [ChatMessageInfoModel]) {
        messages = previousMessages + messages
    }

    func addNewSendMessage(message: ChatMessageInfoModel) {
        messages.append(message)
    }

    func updateNewSendMessageId(newMessage: ChatMessageInfoModel) {
        if let index = messages.firstIndex(where: {
            $0.internalId == newMessage.internalId
        }) {
            messages[index] = newMessage
        }
    }

    func addReceivedMessage(message: ChatMessageInfoModel) {
        if let index = messages.firstIndex(where: {
            $0.id == message.id || $0.internalId == message.internalId
        }) {
            messages[index] = message
        } else {
            messages.append(message)
        }
        if let didReceiveMessage = eventsHandler.onNewMessageReceived,
              message.type == .text {
            didReceiveMessage(message.toChatMessage())
        }

        if let didReceiveUnreadMessage = eventsHandler.onNewUnreadMessages,
           message.type == .text {
            let unreadMessageCount = messages.filter {
                $0.createdOn.value > localParticipantLastRead
            }
            didReceiveUnreadMessage(unreadMessageCount.count)
        }
    }

    func replaceEditedMessage(message: ChatMessageInfoModel) {
        print("not implemented")
    }

    func removeDeletedMessage(message: ChatMessageInfoModel) {
        print("not implemented")
    }

    func replaceSendMessageRetry(message: ChatMessageInfoModel) {
        print("not implemented")
    }

    func addTopicSystemMessage(newTopic: String) {
        let topicUpdatedMessage = ChatMessageInfoModel(
            id: UUID().uuidString,
            type: .topicUpdated,
            content: "Topic has been updated to: `\(newTopic)`",
            createdOn: Iso8601Date()
        )
        messages.append(topicUpdatedMessage)
    }

    func addParticipantsAddedSystemMessage(participants: [ParticipantInfoModel]) {
        let participantAddedMessage = ChatMessageInfoModel(
            id: UUID().uuidString,
            type: .participantsAdded,
            createdOn: Iso8601Date(),
            participants: participants
        )
        messages.append(participantAddedMessage)
    }

    func addParticipantsRemovedSystemMessage(participants: [ParticipantInfoModel]) {
        let participantAddedMessage = ChatMessageInfoModel(
            id: UUID().uuidString,
            type: .participantsRemoved,
            createdOn: Iso8601Date(),
            participants: participants
        )
        messages.append(participantAddedMessage)
    }

    func updateLocalParticipantLastRead(timestamp: Date) {
        if timestamp > localParticipantLastRead {
            localParticipantLastRead = timestamp
        }
    }

    func updateRemoteParticipantEarliestRead(timestamp: Date) {
        if timestamp > remoteParticipantEarliestRead {
            remoteParticipantEarliestRead = timestamp
        }
    }
}
