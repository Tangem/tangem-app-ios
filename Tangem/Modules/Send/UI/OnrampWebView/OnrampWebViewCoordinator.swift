//
//  OnrampWebViewCoordinator.swift
//  Tangem
//
//  Created by Sergey Balashov on 07.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress

class OnrampWebViewCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Dependencies

    @Injected(\.safariManager) private var safariManager: SafariManager

    // MARK: - Root view model

    @Published private(set) var rootViewModel: OnrampWebViewViewModel?

    // MARK: - Child view models

    // TODO:

    // MARK: - Helpers

    private var safariHandle: SafariHandle?

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = .init(
            onrampProvider: options.provider,
            onrampManager: options.onrampManager,
            coordinator: self
        )
    }
}

// MARK: - Options

extension OnrampWebViewCoordinator {
    struct Options {
        let provider: OnrampProvider
        let onrampManager: OnrampManager
    }
}

// MARK: - OnrampWebViewRoutable

extension OnrampWebViewCoordinator: OnrampWebViewRoutable {
    func openURL(url: URL) {
        safariHandle = safariManager.openURL(url) { [weak self] _ in
            self?.safariHandle = nil
        }
    }
}
