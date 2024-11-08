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

    @MainActor
    func tap()

    @MainActor
    func updateState(to state: ActionButtonPresentationState)
}

// TODO: Should be removed in 8238
class BaseActionButtonViewModel: ActionButtonViewModel {
    @Published private(set) var presentationState: ActionButtonPresentationState = .initial

    let model: ActionButtonModel

    init(model: ActionButtonModel) {
        self.model = model
    }

    @MainActor
    func tap() {
        // Should be override
    }

    @MainActor
    func updateState(to state: ActionButtonPresentationState) {
        presentationState = state
    }
}
