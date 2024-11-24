//
//  OnboardingAccessCodeViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 22/03/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

class OnboardingAccessCodeViewModel: ObservableObject, Identifiable {
    let successHandler: (String) -> Void

    @Published var state: OnboardingAccessCodeView.ViewState = .intro
    @Published var firstEnteredCode: String = ""
    @Published var secondEnteredCode: String = ""
    @Published var error: OnboardingAccessCodeView.AccessCodeError = .none

    init(successHandler: @escaping (String) -> Void) {
        self.successHandler = successHandler
    }

    func mainButtonAction() {
        let nextState: OnboardingAccessCodeView.ViewState
        switch state {
        case .intro:
            Analytics.log(.settingAccessCodeStarted)
            nextState = .inputCode
        case .inputCode:
            guard isAccessCodeValid() else {
                return
            }

            Analytics.log(.accessCodeEntered)
            nextState = .repeatCode
        case .repeatCode:
            guard isAccessCodeValid() else {
                return
            }

            Analytics.log(.accessCodeReEntered)
            successHandler(secondEnteredCode)
            return
        }

        state = nextState
    }

    func backButtonAction() {
        UIApplication.shared.endEditing()
        if state == .repeatCode {
            state = .intro
            firstEnteredCode = ""
            secondEnteredCode = ""
            error = .none
        }
    }

    func onDisappearAction() {
        DispatchQueue.main.async {
            self.error = .none
        }
    }

    private func isAccessCodeValid() -> Bool {
        var error: OnboardingAccessCodeView.AccessCodeError = .none
        switch state {
        case .intro: break
        case .inputCode:
            error = firstEnteredCode.count >= 4 ? .none : .tooShort
        case .repeatCode:
            error = firstEnteredCode == secondEnteredCode ? .none : .dontMatch
        }

        self.error = error
        return error == .none
    }
}
