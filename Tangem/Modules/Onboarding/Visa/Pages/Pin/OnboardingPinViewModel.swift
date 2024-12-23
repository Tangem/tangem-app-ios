//
//  OnboardingPinViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 11.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit
import TangemFoundation

protocol OnboardingPinSelectionDelegate: VisaOnboardingAlertPresenter {
    func useSelectedPin(pinCode: String) async throws
}

class OnboardingPinViewModel: ObservableObject {
    @Published var pinCode: String = ""
    @Published var isLoading: Bool = false

    let pinCodeLength = 4

    var isPinCodeValid: Bool {
        pinCode.trimmed().count == pinCodeLength &&
            pinCode.allSatisfy(\.isWholeNumber)
    }

    private weak var delegate: OnboardingPinSelectionDelegate?

    init(delegate: OnboardingPinSelectionDelegate?) {
        self.delegate = delegate
    }

    func submitPinCodeAction() {
        isLoading = true
        UIApplication.shared.endEditing()
        let selectedPinCode = pinCode
        runTask(in: self, isDetached: false) { viewModel in
            do {
                try await viewModel.delegate?.useSelectedPin(pinCode: selectedPinCode)
            } catch {
                if !error.isCancellationError {
                    await viewModel.delegate?.showAlert(error.alertBinder)
                }
            }

            await runOnMain {
                viewModel.isLoading = false
            }
        }
    }
}
