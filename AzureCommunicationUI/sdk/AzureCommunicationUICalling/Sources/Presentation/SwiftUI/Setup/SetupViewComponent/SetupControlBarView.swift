//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import SwiftUI

struct SetupControlBarView: View {
    @ObservedObject var viewModel: SetupControlBarViewModel
    @State var audioDeviceButtonSourceView = UIView()
    let layoutSpacing: CGFloat = 0
    let controlWidth: CGFloat = 315
    let controlHeight: CGFloat = 50
    let horizontalPadding: CGFloat = 16
    let verticalPadding: CGFloat = 13

    @available(iOS 15.0, *)
    @AccessibilityFocusState var focusArea: Bool

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .center) {
                Spacer()
                HStack(alignment: .center, spacing: layoutSpacing) {
                    Spacer()
                    cameraButton
                    Spacer()
                    micButton
                    Spacer()
                    Group {
                        if #available(iOS 15.0, *) {
                            audioDeviceButton
                                .accessibilityFocused($focusArea)
                        } else {
                            audioDeviceButton
                        }
                    }
                    Spacer()
                }
                .frame(width: getWidth(from: geometry),
                       height: controlHeight)
                .padding(.horizontal, getHorizontalPadding(from: geometry))
                .padding(.vertical, verticalPadding)
                .hidden(viewModel.isControlBarHidden())
            }
        }
        .modifier(PopupModalView(isPresented: viewModel.isAudioDeviceSelectionDisplayed) {
            audioDeviceSelectionListView.onDisappear(perform: {
                if #available(iOS 15.0, *) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                        print(focusArea)
                        focusArea = true
                        print(focusArea)
                    })
                }
            })
        })
    }

    var cameraButton: some View {
        IconWithLabelButton(viewModel: viewModel.cameraButtonViewModel,
                            isDrawerClosed: $viewModel.isAudioDeviceSelectionDisplayed)
            .accessibility(identifier: AccessibilityIdentifier.toggleVideoAccessibilityID.rawValue)
    }

    var micButton: some View {
        IconWithLabelButton(viewModel: viewModel.micButtonViewModel,
                            isDrawerClosed: $viewModel.isAudioDeviceSelectionDisplayed)
            .accessibility(identifier: AccessibilityIdentifier.togglMicAccessibilityID.rawValue)
    }

    var audioDeviceButton: some View {
        IconWithLabelButton(viewModel: viewModel.audioDeviceButtonViewModel,
                            isDrawerClosed: $viewModel.isAudioDeviceSelectionDisplayed)
    }

    var audioDeviceSelectionListView: some View {
        CompositeAudioDevicesList(isPresented: $viewModel.isAudioDeviceSelectionDisplayed,
                                  viewModel: viewModel.audioDevicesListViewModel,
                                  sourceView: UIHostingController(rootView: cameraButton).view)
    }

    private func getWidth(from geometry: GeometryProxy) -> CGFloat {
        if controlWidth > geometry.size.width {
            return geometry.size.width
        }
        return controlWidth
    }

    private func getHorizontalPadding(from geometry: GeometryProxy) -> CGFloat {
        if controlWidth > geometry.size.width {
            return 0
        }
        return (geometry.size.width - controlWidth) / 2
    }
}
