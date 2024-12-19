//
//  VisaOnboardingInProgressViewModel.swift
//  TangemApp
//
//  Created by Andrew Son on 19.12.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

protocol VisaOnboardingInProgressDelegate: VisaOnboardingAlertPresenter {
    func canProceedOnboarding() async throws -> Bool
    @MainActor
    func proceedFromInProgress() async
}

class VisaOnboardingInProgressViewModel: ObservableObject {
    @Published var isLoading: Bool = false

    var title: String {
        state.title
    }

    var description: String {
        state.description
    }

    private let state: State
    private weak var delegate: VisaOnboardingInProgressDelegate?

    init(state: VisaOnboardingInProgressViewModel.State, delegate: VisaOnboardingInProgressDelegate?) {
        self.state = state
        self.delegate = delegate
    }

    func refreshAction() {
        isLoading = true
        runTask(in: self, isDetached: false) { viewModel in
            do {
                if try await viewModel.delegate?.canProceedOnboarding() ?? false {
                    await viewModel.delegate?.proceedFromInProgress()
                }
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

extension VisaOnboardingInProgressViewModel {
    enum State {
        case accountDeployment
        case issuerProcessing

        var title: String {
            switch self {
            case .accountDeployment:
                return "Getting Everything Ready!"
            case .issuerProcessing:
                return "Almost done!"
            }
        }

        // Temp texts
        var description: String {
            switch self {
            case .accountDeployment:
                return "We're working on creating your Blockchain account. Please hang tight!"
            case .issuerProcessing:
                return "Issuer is processing your information. Soon everything will be working as expected."
            }
        }
    }
}
