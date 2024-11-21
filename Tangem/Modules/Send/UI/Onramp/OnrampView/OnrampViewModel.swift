//
//  OnrampViewModel.swift
//  TangemApp
//
//  Created by Sergey Balashov on 15.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress

class OnrampViewModel: ObservableObject, Identifiable {
    @Published private(set) var onrampAmountViewModel: OnrampAmountViewModel
    @Published private(set) var onrampProvidersCompactViewModel: OnrampProvidersCompactViewModel

    @Published private(set) var notificationInputs: [NotificationViewInput] = []
    @Published private(set) var notificationButtonIsLoading = false

    weak var router: OnrampSummaryRoutable?

    private let interactor: OnrampInteractor
    private let notificationManager: NotificationManager
    private var bag: Set<AnyCancellable> = []

    init(
        onrampAmountViewModel: OnrampAmountViewModel,
        onrampProvidersCompactViewModel: OnrampProvidersCompactViewModel,
        notificationManager: NotificationManager,
        interactor: OnrampInteractor
    ) {
        self.onrampAmountViewModel = onrampAmountViewModel
        self.onrampProvidersCompactViewModel = onrampProvidersCompactViewModel
        self.notificationManager = notificationManager
        self.interactor = interactor

        bind()
    }

    func openOnrampSettingsView() {
        router?.openOnrampSettingsView()
    }
}

// MARK: - Private

private extension OnrampViewModel {
    func bind() {
        notificationManager
            .notificationPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, notificationInputs in
                viewModel.notificationInputs = notificationInputs
            }
            .store(in: &bag)

        interactor
            .isLoadingPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, isLoading in
                viewModel.notificationButtonIsLoading = isLoading
            }
            .store(in: &bag)
    }
}

// MARK: - SendStepViewAnimatable

extension OnrampViewModel: SendStepViewAnimatable {
    func viewDidChangeVisibilityState(_ state: SendStepVisibilityState) {}
}
