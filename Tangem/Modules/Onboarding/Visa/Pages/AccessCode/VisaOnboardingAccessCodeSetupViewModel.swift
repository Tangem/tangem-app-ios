//
//  VisaOnboardingAccessCodeSetupViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 19.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import TangemFoundation
import TangemVisa

protocol VisaOnboardingAccessCodeSetupDelegate: VisaOnboardingAlertPresenter {
    func useSelectedCode(accessCode: String) async throws

    func closeOnboarding()
}

class VisaOnboardingAccessCodeSetupViewModel: ObservableObject {
    @Published var accessCode: String = ""
    @Published private(set) var viewState: State = .accessCode
    @Published private(set) var isButtonBusy: Bool = false
    @Published private(set) var isButtonDisabled: Bool = true
    @Published private(set) var isInputDisabled: Bool = false
    @Published private(set) var errorMessage: String? = nil

    private var selectedAccessCode: String = ""
    private var accessCodeInputSubscription: AnyCancellable?

    private var accessCodeValidator: VisaAccessCodeValidator
    private weak var delegate: VisaOnboardingAccessCodeSetupDelegate?

    init(
        accessCodeValidator: VisaAccessCodeValidator,
        delegate: VisaOnboardingAccessCodeSetupDelegate
    ) {
        self.accessCodeValidator = accessCodeValidator
        self.delegate = delegate

        bind()
    }

    func mainButtonAction() {
        switch viewState {
        case .accessCode:
            goToRepeatAccessCode()
        case .repeatAccessCode:
            finishAccessCodeSetup()
        }
    }

    func goBack() -> Bool {
        switch viewState {
        case .accessCode:
            UIApplication.shared.endEditing()
            selectedAccessCode = ""
            accessCode = ""
            errorMessage = nil
            return true
        case .repeatAccessCode:
            withAnimation {
                viewState = .accessCode
                accessCode = selectedAccessCode
                selectedAccessCode = ""
                errorMessage = nil
            }
            return false
        }
    }

    private func bind() {
        accessCodeInputSubscription = $accessCode
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.errorMessage = nil
                self?.isButtonDisabled = true
            })
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, input in
                viewModel.processInput(accessCodeInput: input)
            }
    }

    private func processInput(accessCodeInput: String) {
        if accessCodeInput.isEmpty {
            errorMessage = nil
            isButtonDisabled = true
            return
        }

        do {
            try isAccessCodeValid(accessCode: accessCodeInput)
            errorMessage = nil
            isButtonDisabled = false
        } catch let validationError as ValidationError {
            errorMessage = validationError.description
            isButtonDisabled = true
        } catch let visaValidationError as VisaAccessCodeValidationError {
            let appError = ValidationError(visaValidationError: visaValidationError)
            errorMessage = appError.description
            isButtonDisabled = true
        } catch {
            errorMessage = error.localizedDescription
            isButtonDisabled = true
        }
    }

    private func isAccessCodeValid(accessCode: String) throws {
        switch viewState {
        case .accessCode:
            try accessCodeValidator.validateAccessCode(accessCode: accessCode)
        case .repeatAccessCode:
            if accessCode != selectedAccessCode {
                throw ValidationError.codesDoNotMatch
            }
        }
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        AppLog.shared.debug("[VisaAccessCodeViewModel] - \(message())")
    }
}

private extension VisaOnboardingAccessCodeSetupViewModel {
    func goToRepeatAccessCode() {
        selectedAccessCode = accessCode
        withAnimation {
            viewState = .repeatAccessCode
            accessCode = ""
        }
    }

    func finishAccessCodeSetup() {
        if selectedAccessCode.isEmpty {
            log("Main button on access code setup is enabled while error is present. State: \(viewState.title)")
            return
        }

        UIApplication.shared.endEditing()
        isButtonBusy = true
        // We need to disable input, because a lot of operations will be done on this page
        // May be changed)
        isInputDisabled = true
        runTask(in: self, isDetached: false) { viewModel in
            do {
                try await viewModel.delegate?.useSelectedCode(accessCode: viewModel.selectedAccessCode)
            } catch {
                if !error.isCancellationError {
                    viewModel.log("Failed to use selected access code. Reason: \(error)")
                    await viewModel.showRetryAlert(for: error)
                }
            }

            await runOnMain {
                viewModel.isInputDisabled = false
                viewModel.isButtonBusy = false
            }
        }
    }

    @MainActor
    func showRetryAlert(for error: Error) async {
        let alert = Alert(
            title: Text(Localization.commonError),
            message: Text("Failed to activate card. Error: \(error.localizedDescription)"),
            primaryButton: .default(
                Text(Localization.alertButtonTryAgain),
                action: { [weak self] in
                    self?.finishAccessCodeSetup()
                }
            ),
            secondaryButton: .destructive(
                Text("Cancel Activation"),
                action: { [weak self] in
                    self?.delegate?.closeOnboarding()
                }
            )
        )
        await delegate?.showAlert(AlertBinder(alert: alert))
    }
}

extension VisaOnboardingAccessCodeSetupViewModel {
    enum ValidationError: String, Error {
        case accessCodeTooShort
        case codesDoNotMatch

        var description: String {
            switch self {
            case .accessCodeTooShort: return Localization.onboardingAccessCodeTooShort
            case .codesDoNotMatch: return Localization.onboardingAccessCodesDoesntMatch
            }
        }

        init(visaValidationError: VisaAccessCodeValidationError) {
            switch visaValidationError {
            case .accessCodeIsTooShort:
                self = .accessCodeTooShort
            }
        }
    }
}

extension VisaOnboardingAccessCodeSetupViewModel {
    enum State {
        case accessCode
        case repeatAccessCode

        var title: String {
            switch self {
            case .accessCode: return Localization.onboardingAccessCodeIntroTitle
            case .repeatAccessCode: return Localization.onboardingAccessCodeRepeatCodeTitle
            }
        }

        var description: String {
            "The access code will be used manage your payment account and protect it from unauthorized access"
        }

        var buttonTitle: String {
            switch self {
            case .accessCode: return Localization.commonContinue
            case .repeatAccessCode: return "Start activation"
            }
        }

        var isButtonWithLogo: Bool {
            switch self {
            case .accessCode: return false
            case .repeatAccessCode: return true
            }
        }
    }
}
