//
//  CardOperationViewModel.swift
//  Tangem
//
//  Created by Alexander Osokin on 20.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class CardOperationViewModel: ObservableObject {
    @Published var error: AlertBinder? = nil
    @Published var isLoading: Bool = false

    let title: String
    let buttonTitle: String
    let shouldPopToRoot: Bool
    let alert: String
    let actionButtonPressed: (_ completion: @escaping (Result<Void, Error>) -> Void) -> Void

    private weak var coordinator: CardOperationRoutable?
    private var bag: Set<AnyCancellable> = []

    init(
        title: String,
        buttonTitle: String = Localization.commonSaveChanges,
        shouldPopToRoot: Bool = false,
        alert: String,
        actionButtonPressed: @escaping (@escaping (Result<Void, Error>) -> Void) -> Void,
        coordinator: CardOperationRoutable
    ) {
        self.title = title
        self.buttonTitle = buttonTitle
        self.shouldPopToRoot = shouldPopToRoot
        self.alert = alert
        self.actionButtonPressed = actionButtonPressed
        self.coordinator = coordinator
    }

    func onTap() {
        isLoading = true
        actionButtonPressed { [weak self] result in
            DispatchQueue.main.async {
                self?.handleCompletion(result)
            }
        }
    }

    private func handleCompletion(_ result: Result<Void, Error>) {
        isLoading = false

        switch result {
        case .success:
            DispatchQueue.main.async {
                if self.shouldPopToRoot {
                    self.popToRoot()
                } else {
                    self.dismissCardOperation()
                }
            }
        case .failure(let error):
            if error.isCancellationError {
                return
            }

            self.error = error.alertBinder
        }
    }
}

// MARK: - Navigantion

extension CardOperationViewModel {
    func popToRoot() {
        coordinator?.popToRoot()
    }

    func dismissCardOperation() {
        coordinator?.dismissCardOperation()
    }
}
