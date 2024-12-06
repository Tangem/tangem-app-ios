//
//  OnrampCountryDetectionCoordinator.swift
//  TangemApp
//
//  Created by Sergey Balashov on 28.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemExpress

class OnrampCountryDetectionCoordinator: CoordinatorObject {
    let dismissAction: Action<CloseOption?>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: OnrampCountryDetectionViewModel?

    // MARK: - Child view models

    @Published var onrampCountrySelectorViewModel: OnrampCountrySelectorViewModel?

    private var options: Options?

    required init(dismissAction: @escaping Action<CloseOption?>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        self.options = options
        rootViewModel = .init(country: options.country, repository: options.repository, coordinator: self)
    }
}

// MARK: - Options

extension OnrampCountryDetectionCoordinator {
    struct Options {
        let country: OnrampCountry
        let repository: any OnrampRepository
        let dataRepository: any OnrampDataRepository
    }

    enum CloseOption {
        case closeOnramp
    }
}

// MARK: - OnrampCountryDetectionRoutable

extension OnrampCountryDetectionCoordinator: OnrampCountryDetectionRoutable {
    func openChangeCountry() {
        guard let options else {
            assertionFailure("OnrampCountryDetectionCoordinator.Options not found")
            return
        }

        onrampCountrySelectorViewModel = OnrampCountrySelectorViewModel(
            repository: options.repository,
            dataRepository: options.dataRepository,
            coordinator: self
        )
    }

    func dismissConfirmCountryView() {
        dismiss(with: nil)
    }

    func dismissOnramp() {
        dismiss(with: .closeOnramp)
    }
}

// MARK: - OnrampCountrySelectorRoutable

extension OnrampCountryDetectionCoordinator: OnrampCountrySelectorRoutable {
    func dismissCountrySelector() {
        onrampCountrySelectorViewModel = nil
    }
}
