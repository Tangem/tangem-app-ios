//
//  OnrampRedirectingViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 07.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemExpress

final class OnrampRedirectingViewModel: ObservableObject {
    // MARK: - ViewState

    var title: String { "\(Localization.commonBuy) \(tokenItem.name)" }
    var providerImageURL: URL? { onrampProvider.provider.imageURL }
    var providerName: String { onrampProvider.provider.name }

    @Published var alert: AlertBinder?

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let onrampProvider: OnrampProvider
    private let onrampManager: OnrampManager
    private weak var coordinator: OnrampRedirectingRoutable?

    init(
        tokenItem: TokenItem,
        onrampProvider: OnrampProvider,
        onrampManager: OnrampManager,
        coordinator: OnrampRedirectingRoutable
    ) {
        self.tokenItem = tokenItem
        self.onrampProvider = onrampProvider
        self.onrampManager = onrampManager
        self.coordinator = coordinator
    }

    func loadRedirectData() async {
        do {
//            let redirectSettings = OnrampRedirectSettings(successURL: "https://tangem.com/onramp/success", theme: "light", language: "en")
//            let item = try onrampProvider.manager.makeOnrampQuotesRequestItem()
//            let requestItem = OnrampRedirectDataRequestItem(quotesItem: item, redirectSettings: redirectSettings)
            let data = try await onrampManager.loadRedirectData(provider: onrampProvider)

            guard let url = URL(string: data.widgetUrl) else {
                throw Error.wrongURL
            }

            coordinator?.openURL(url: url)
        } catch {
            // TODO: close view ?
            alert = error.alertBinder
        }
    }
}

extension OnrampRedirectingViewModel {
    enum Error: LocalizedError {
        case wrongURL
    }
}
