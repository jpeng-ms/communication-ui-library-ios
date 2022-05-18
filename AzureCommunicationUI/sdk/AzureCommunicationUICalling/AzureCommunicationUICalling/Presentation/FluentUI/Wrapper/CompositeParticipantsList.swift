//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import SwiftUI
import FluentUI
import Combine

struct CompositeParticipantsList: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var isInfoHeaderDisplayed: Bool
    @Binding var isVoiceOverEnabled: Bool
    @State var updatedId: String = ""
//    @Binding var updId: String?
    @ObservedObject var viewModel: ParticipantsListViewModel
    let avatarViewManager: AvatarViewManager
    let sourceView: UIView
    private var cancellables = Set<AnyCancellable>()

    init(isPresented: Binding<Bool>,
         isInfoHeaderDisplayed: Binding<Bool>,
         isVoiceOverEnabled: Binding<Bool>,
//         updId: Binding<String?>,
         viewModel: ParticipantsListViewModel,
         avatarViewManager: AvatarViewManager,
         sourceView: UIView) {
//        self._updId = updId
        self._isPresented = isPresented
        self._isInfoHeaderDisplayed = isInfoHeaderDisplayed
        self._isVoiceOverEnabled = isVoiceOverEnabled
        self.viewModel = viewModel
        self.avatarViewManager = avatarViewManager
        self.sourceView = sourceView
        avatarViewManager.updatedParticipantIdSubject
            .sink {
                self.updatedId = $0
            }.store(in: &cancellables)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented,
                    isInfoHeaderDisplayed: $isInfoHeaderDisplayed,
                    isVoiceOverEnabled: $isVoiceOverEnabled)
    }

    func makeUIViewController(context: Context) -> DrawerContainerViewController<ParticipantsListCellViewModel> {
        let controller = ParticipantsListViewController(items: getParticipantsList(),
                                                        sourceView: sourceView,
                                                        avatarViewManager: avatarViewManager)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: DrawerContainerViewController<ParticipantsListCellViewModel>,
                                context: Context) {
        uiViewController.updateDrawerList(items: getParticipantsList())
    }

    static func dismantleUIViewController(_ controller: DrawerContainerViewController<ParticipantsListCellViewModel>,
                                          coordinator: Coordinator) {
        controller.dismissDrawer()
    }

    private func getParticipantsList() -> [ParticipantsListCellViewModel] {
        return viewModel.sortedParticipants(with: avatarViewManager)
    }

    class Coordinator: NSObject, DrawerControllerDelegate {
        @Binding var isPresented: Bool
        @Binding var isInfoHeaderDisplayed: Bool
        @Binding var isVoiceOverEnabled: Bool

        init(isPresented: Binding<Bool>,
             isInfoHeaderDisplayed: Binding<Bool>,
             isVoiceOverEnabled: Binding<Bool>) {
            self._isPresented = isPresented
            self._isInfoHeaderDisplayed = isInfoHeaderDisplayed
            self._isVoiceOverEnabled = isVoiceOverEnabled
        }

        func drawerControllerDidDismiss(_ controller: DrawerController) {
            isPresented = false
            if !isVoiceOverEnabled {
                isInfoHeaderDisplayed = false
            }
        }
    }
}
