//
//  ActionButtonViewModel.swift
//  Tangem
//
//  Created by GuitarKitty on 24.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class BaseActionButtonViewModel: ObservableObject, Identifiable {
    @Published private(set) var presentationState: ActionButtonPresentationState = .unexplicitLoading

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
