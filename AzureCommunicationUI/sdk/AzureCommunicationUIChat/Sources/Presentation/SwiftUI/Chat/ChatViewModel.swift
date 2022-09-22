//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation
import AzureCommunicationCommon
import AzureCommunicationChat
import AzureCore
import Combine

class ChatViewModel: ObservableObject {
    private let compositeViewModelFactory: CompositeViewModelFactoryProtocol
    private let messageRepository: MessageRepositoryManagerProtocol

    private let logger: Logger
    private let store: Store<AppState>
    private let localizationProvider: LocalizationProviderProtocol
    private let accessibilityProvider: AccessibilityProviderProtocol

    private var cancellables = Set<AnyCancellable>()

    let threadViewModel: ThreadViewModel
    let typingParticipantsViewModel: TypingParticipantsViewModel
    let messageInputViewModel: MessageInputViewModel

    var participantsLastUpdatedTimestamp = Date()

    @Published var participants: [ParticipantInfoModel] = []

    init(compositeViewModelFactory: CompositeViewModelFactoryProtocol,
         messageRepository: MessageRepositoryManagerProtocol,
         logger: Logger,
         store: Store<AppState>,
         localizationProvider: LocalizationProviderProtocol,
         accessibilityProvider: AccessibilityProviderProtocol,
         isIpadInterface: Bool) {
        self.compositeViewModelFactory = compositeViewModelFactory
        self.messageRepository = messageRepository
        self.logger = logger
        self.store = store
        self.localizationProvider = localizationProvider
        self.accessibilityProvider = accessibilityProvider

        self.threadViewModel = compositeViewModelFactory.makeThreadViewModel(
            dispatch: store.dispatch,
            localUser: store.state.chatState.localUser)
        self.typingParticipantsViewModel = compositeViewModelFactory.makeTypingParticipantsViewModel()
        self.messageInputViewModel = compositeViewModelFactory.makeMessageInputViewModel(
            dispatch: store.dispatch,
            localUser: store.state.chatState.localUser)

        store.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.receive(state)
            }.store(in: &cancellables)
    }

    func startChat() {
        store.dispatch(action: .chatViewLaunched)
        store.dispatch(action: .participantsAction(.retrieveParticipantsListTriggered))
    }

    func getPreviousMessages() {
        store.dispatch(action: .chatAction(.fetchPreviousMessagesTriggered))
    }

    func backButtonTapped() {
        print("Back button pressed")
        store.dispatch(action: .chatViewHeadless)
    }

    //    func getMessages() {
    //        chatSDKWrapper.getMessages() { (chatMessages) in
    //            DispatchQueue.main.async { [self] in
    //                self.chatMessages = chatMessages
    //            }
    //        }
    //    }

    //    func receiveMessage(response: TrouterEvent) {
    //        print("Receiving a Message...")
    //        switch response {
    //        case let .chatMessageReceivedEvent(event):
    //            DispatchQueue.main.async { [self] in
    //                chatMessages.append(CompositeChatMessage(chatMessageEvent: event))
    //            }
    //        default:
    //            return
    //        }
    //    }

    func receive(_ state: AppState) {
        print("ChatViewModel receive new app state, count=\(state.chatState.messages.count)")

        if self.participantsLastUpdatedTimestamp < state.participantsState.participantsUpdatedTimestamp {
            self.participants = Array(state.participantsState.participantsInfoMap.values)
        }

        self.threadViewModel.update(chatState: state.chatState, participantsState: state.participantsState)
        self.typingParticipantsViewModel.update(participantsState: state.participantsState)
    }
}
