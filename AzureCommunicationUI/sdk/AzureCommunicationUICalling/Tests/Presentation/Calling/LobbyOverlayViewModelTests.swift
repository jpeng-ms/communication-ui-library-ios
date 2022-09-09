//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation
import XCTest
@testable import AzureCommunicationUICalling

class LobbyOverlayViewModelTests: XCTestCase {
    private var localizationProvider: LocalizationProviderMocking!

    func test_lobbyOverlayViewModel_displays_title_from_AppLocalization() {
        let sut = makeSUT()
        XCTAssertEqual(sut.title, "Waiting for host")
    }

    func test_lobbyOverlayViewModel_displays_subtitle_from_AppLocalization() {
        let sut = makeSUT()
        XCTAssertEqual(sut.subtitle, "Someone in the meeting will let you in soon")
    }

    func test_lobbyOverlayViewModel_displays_subtitle_from_LocalizationMocking() {
        let sut = makeSUTLocalizationMocking()
        XCTAssertEqual(sut.subtitle, "AzureCommunicationUICalling.LobbyView.Text.WaitingDetails")
        XCTAssertTrue(localizationProvider.isGetLocalizedStringCalled)
    }
}

extension LobbyOverlayViewModelTests {
    func makeSUT() -> LobbyOverlayViewModel {
        setupMocking()
        return LobbyOverlayViewModel(localizationProvider:
                                        LocalizationProvider(logger: LoggerMocking()),
                                     accessibilityProvider: AccessibilityProviderMocking())
    }

    func makeSUTLocalizationMocking() -> LobbyOverlayViewModel {
        setupMocking()
        return LobbyOverlayViewModel(localizationProvider: localizationProvider,
                                     accessibilityProvider: AccessibilityProviderMocking())
    }

    func setupMocking() {
        localizationProvider = LocalizationProviderMocking()
    }
}
