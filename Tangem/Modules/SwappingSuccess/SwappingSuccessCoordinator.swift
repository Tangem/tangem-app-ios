//
//  SwappingSuccessCoordinator.swift
//  Tangem
//
//  Created by Sergey Balashov on 13.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class SwappingSuccessCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: SwappingSuccessViewModel?

    // MARK: - Child view models

    @Published var webViewContainerViewModel: WebViewContainerViewModel?

    private let factory: SwappingModulesFactory

    required init(
        factory: SwappingModulesFactory,
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.factory = factory
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = factory.makeSwappingSuccessViewModel(inputModel: options.inputModel, coordinator: self)
    }
}

// MARK: - Options

extension SwappingSuccessCoordinator {
    struct Options {
        let inputModel: SwappingSuccessInputModel
    }
}

// MARK: - SwappingSuccessRoutable

extension SwappingSuccessCoordinator: SwappingSuccessRoutable {
    func didTapCloseButton() {
        dismiss()
    }

    func openExplorer(url: URL?, currencyName: String) {
        webViewContainerViewModel = WebViewContainerViewModel(
            url: url,
            title: Localization.commonExplorerFormat(currencyName),
            withCloseButton: true
        )
    }
}
