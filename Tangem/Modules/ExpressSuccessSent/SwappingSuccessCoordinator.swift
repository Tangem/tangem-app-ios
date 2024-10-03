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

    // MARK: - Dependencies

    @Injected(\.safariManager) private var safariManager: SafariManager

    // MARK: - Root view model

    @Published private(set) var rootViewModel: ExpressSuccessSentViewModel?

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        switch options {
        case .express(let factory, let data):
            rootViewModel = factory.makeExpressSuccessSentViewModel(data: data, coordinator: self)
        }
    }
}

// MARK: - Options

extension SwappingSuccessCoordinator {
    enum Options {
        case express(factory: ExpressModulesFactory, SentExpressTransactionData)
    }
}

// MARK: - ExpressSuccessSentRoutable

extension SwappingSuccessCoordinator: ExpressSuccessSentRoutable {
    func openWebView(url: URL?) {
        if let url {
            safariManager.openURL(url)
        }
    }

    func close() {
        dismiss()
    }
}
