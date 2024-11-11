//
//  OnboardingPinViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 11.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class OnboardingPinViewModel: ObservableObject {
    @Published var pinCode: String = ""

    let pinCodeLength = 4

    var isPinCodeValid: Bool {
        pinCode.trimmed().count == pinCodeLength &&
            pinCode.allSatisfy(\.isWholeNumber)
    }

    private let pinCodeSaver: SavePinCode

    init(pinCodeSaver: @escaping SavePinCode) {
        self.pinCodeSaver = pinCodeSaver
    }

    func submitPinCodeAction() {
        pinCodeSaver(pinCode)
    }
}

extension OnboardingPinViewModel {
    typealias SavePinCode = (String) -> Void
}
