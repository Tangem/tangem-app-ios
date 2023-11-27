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

    @Published private(set) var legacyRootViewModel: SwappingSuccessViewModel?
    @Published private(set) var rootViewModel: ExpressSuccessSentViewModel?

    // MARK: - Child view models

    @Published var webViewContainerViewModel: WebViewContainerViewModel?

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        switch options {
        case .swapping(let factory, let inputModel):
            legacyRootViewModel = factory.makeSwappingSuccessViewModel(inputModel: inputModel, coordinator: self)
        case .express(let factory, let data):
            rootViewModel = factory.makeExpressSuccessSentViewModel(data: data, coordinator: self)
        }
    }
}

// MARK: - Options

extension SwappingSuccessCoordinator {
    enum Options {
        case swapping(factory: SwappingModulesFactory, SwappingSuccessInputModel)
        case express(factory: ExpressModulesFactory, SentExpressTransactionData)
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

// MARK: - ExpressSuccessSentRoutable

extension SwappingSuccessCoordinator: ExpressSuccessSentRoutable {
    func openWebView(url: URL?, title: String) {
        webViewContainerViewModel = WebViewContainerViewModel(url: url, title: title, withCloseButton: true)
    }

    func close() {
        dismiss()
    }
}
