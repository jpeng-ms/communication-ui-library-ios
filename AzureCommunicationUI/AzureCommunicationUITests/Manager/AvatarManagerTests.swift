//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import XCTest
import UIKit
import AzureCommunicationCommon
@testable import AzureCommunicationUI

class AvatarManagerTests: XCTestCase {
    var mockStoreFactory = StoreFactoryMocking()

    override func setUp() {
        super.setUp()
    }

    func test_avatarManager_when_setLocalAvatar_then_getLocalAvatar_returnsSameUIImage() {
        guard let mockImage = UIImage(named: "Icon/ic_fluent_call_end_24_filled",
                                      in: Bundle(for: CallComposite.self),
                                      compatibleWith: nil) else {
            XCTFail("UIImage does not exist")
            return
        }
        let mockAvatarManager = makeSUT(mockImage)
        let mockImageData = mockImage.cgImage?.bitsPerPixel
        let setAvatar = mockAvatarManager.getLocalPersonaData()?.avatarImage
        let setAvatarImageData = setAvatar?.cgImage?.bitsPerPixel
        XCTAssertEqual(mockImageData, setAvatarImageData)
    }

    func test_avatarManager_setRemoteParticipantPersonaData_when_personeDataSet_then_personaDataUpdated() {
        guard let mockImage = UIImage(named: "Icon/ic_fluent_call_end_24_filled",
                                      in: Bundle(for: CallComposite.self),
                                      compatibleWith: nil) else {
            XCTFail("UIImage does not exist")
            return
        }
        let sut = makeSUT()
        let personaData = PersonaData(mockImage)
        let id = UUID().uuidString
        let result = sut.setRemoteParticipantPersonaData(for: CommunicationUserIdentifier(id),
                                                         personaData: personaData)
        guard case let .success(resultValue) = result else {
            XCTFail("Failed with result validation")
            return
        }
        XCTAssertTrue(resultValue)
        XCTAssertEqual(sut.avatarStorage.value(forKey: id)?.avatarImage!, mockImage)
    }
}

extension AvatarManagerTests {
    private func makeSUT(_ image: UIImage) -> AvatarViewManager {
        let mockPersonaData = PersonaData(image, renderDisplayName: "")
        let mockDataOptions = CommunicationUILocalDataOptions(mockPersonaData)
        return AvatarViewManager(store: mockStoreFactory.store,
                                 localDataOptions: mockDataOptions)

    }

    private func makeSUT() -> AvatarViewManager {
        return AvatarViewManager(store: mockStoreFactory.store,
                                 localDataOptions: nil)

    }
}
