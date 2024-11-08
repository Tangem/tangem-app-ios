//
//  OnrampWebViewViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 07.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemExpress

final class OnrampWebViewViewModel: ObservableObject {
    // MARK: - ViewState

    var providerImageURL: URL? { onrampProvider.provider.imageURL }
    var providerName: String { onrampProvider.provider.name }

    @Published var alert: AlertBinder?

    // MARK: - Dependencies

    private let onrampProvider: OnrampProvider
    private let onrampManager: OnrampManager
    private weak var coordinator: OnrampWebViewRoutable?

    init(
        onrampProvider: OnrampProvider,
        onrampManager: OnrampManager,
        coordinator: OnrampWebViewRoutable
    ) {
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

extension OnrampWebViewViewModel {
    enum Error: LocalizedError {
        case wrongURL
    }
}
