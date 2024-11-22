//
//  ActionButtonViewModel.swift
//  Tangem
//
//  Created by GuitarKitty on 24.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol ActionButtonViewModel: ObservableObject, Identifiable {
    var presentationState: ActionButtonPresentationState { get }
    var model: ActionButtonModel { get }
    var isDisabled: Bool { get }

    @MainActor
    func tap()

    @MainActor
    func updateState(to state: ActionButtonPresentationState)
}

extension ActionButtonViewModel {
    var isDisabled: Bool {
        switch presentationState {
        case .initial, .idle: false
        case .disabled, .loading: true
        }
    }
}
