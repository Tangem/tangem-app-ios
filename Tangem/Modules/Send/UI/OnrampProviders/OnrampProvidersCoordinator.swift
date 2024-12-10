//
//  OnrampProvidersCoordinator.swift
//  Tangem
//
//  Created by Sergey Balashov on 25.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class OnrampProvidersCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: OnrampProvidersViewModel?

    // MARK: - Child view models

    @Published var onrampPaymentMethodsViewModel: OnrampPaymentMethodsViewModel?

    // MARK: - Dependencies

    private let onrampProvidersBuilder: OnrampProvidersBuilder
    private let onrampPaymentMethodsBuilder: OnrampPaymentMethodsBuilder

    required init(
        onrampProvidersBuilder: OnrampProvidersBuilder,
        onrampPaymentMethodsBuilder: OnrampPaymentMethodsBuilder,
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.onrampProvidersBuilder = onrampProvidersBuilder
        self.onrampPaymentMethodsBuilder = onrampPaymentMethodsBuilder
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = onrampProvidersBuilder.makeOnrampProvidersViewModel(coordinator: self)
    }
}

// MARK: - Options

extension OnrampProvidersCoordinator {
    enum Options {
        case `default`
    }
}

// MARK: - OnrampProvidersRoutable

extension OnrampProvidersCoordinator: OnrampProvidersRoutable {
    func openOnrampPaymentMethods() {
        onrampPaymentMethodsViewModel = onrampPaymentMethodsBuilder.makeOnrampPaymentMethodsViewModel(coordinator: self)
    }

    func closeOnrampProviders() {
        dismiss()
    }
}

// MARK: - OnrampPaymentMethodsRoutable

extension OnrampProvidersCoordinator: OnrampPaymentMethodsRoutable {
    func closeOnrampPaymentMethodsView() {
        onrampPaymentMethodsViewModel = nil
    }
}
