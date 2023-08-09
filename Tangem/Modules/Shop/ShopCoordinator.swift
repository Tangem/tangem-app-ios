//
//  ShopCoordinator.swift
//  Tangem
//
//  Created by Alexander Osokin on 15.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class ShopCoordinator: CoordinatorObject {
    var dismissAction: Action
    var popToRootAction: ParamsAction<PopToRootOptions>

    // MARK: - Main view model

    @Published private(set) var shopViewModel: ShopViewModel? = nil

    // MARK: - Child view models

    @Published var pushedWebViewModel: WebViewContainerViewModel? = nil

    @Published var webShopUrl: URL? = nil

    // MARK: - Private helpers

    @Published var emptyModel: Int? = nil // Fix single navigation link issue

    required init(dismissAction: @escaping Action, popToRootAction: @escaping ParamsAction<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: ShopCoordinator.Options = .init()) {
        Analytics.log(.shopScreenOpened)

        if let webShopUrl = ShopWebHelper().webShopUrl {
            self.webShopUrl = webShopUrl
        } else {
            fatalError("Did you return the availability of Shopify? There's an untested dynamic Shopify system that hasn't been tested yet (IOS-3910)")
            shopViewModel = ShopViewModel(coordinator: self)
        }
    }
}

extension ShopCoordinator {
    struct Options {}
}

extension ShopCoordinator: ShopViewRoutable {
    func openWebCheckout(at url: URL) {
        pushedWebViewModel = WebViewContainerViewModel(
            url: url,
            title: Localization.shopWebCheckoutTitle,
            addLoadingIndicator: true
        )
    }

    func closeWebCheckout() {
        pushedWebViewModel = nil
    }
}
