//
//  ActionButtonViewModel.swift
//  Tangem
//
//  Created by GuitarKitty on 24.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol ActionButtonViewModel: ObservableObject, Identifiable {
    var viewState: ActionButtonState { get }
    var model: ActionButtonModel { get }
    var isDisabled: Bool { get }
    var alert: AlertBinder? { get set }

    @MainActor
    func tap()

    @MainActor
    func updateState(to state: ActionButtonState)
}

extension ActionButtonViewModel {
    var isDisabled: Bool {
        switch viewState {
        case .initial, .idle: false
        case .disabled, .loading: true
        }
    }

    func trackTapEvent() {
        ActionButtonsAnalyticsService.trackActionButtonTap(button: model, state: viewState)
    }
}
