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

    var title: String {
        "\(Localization.commonBuy) \(tokenItem.name)"
    }

    var providerImageURL: URL? {
        interactor.onrampProvider?.provider.imageURL
    }

    var providerName: String {
        interactor.onrampProvider?.provider.name ?? Localization.expressProvider
    }

    @Published var alert: AlertBinder?

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let interactor: OnrampRedirectingInteractor
    private weak var coordinator: OnrampRedirectingRoutable?

    private var colorScheme: ColorScheme = .light

    init(
        tokenItem: TokenItem,
        interactor: OnrampRedirectingInteractor,
        coordinator: OnrampRedirectingRoutable
    ) {
        self.tokenItem = tokenItem
        self.interactor = interactor
        self.coordinator = coordinator
    }

    func onAppear() {
        logOpening()
    }

    func loadRedirectData() async {
        do {
            try await interactor.loadRedirectData(redirectSettings: makeOnrampRedirectSettings())
        } catch {
            await runOnMain {
                alert = AlertBuilder.makeOkErrorAlert(message: error.localizedDescription) { [weak self] in
                    self?.coordinator?.dismissOnrampRedirecting()
                }
            }
        }
    }

    func update(colorScheme: ColorScheme) {
        self.colorScheme = colorScheme
    }
}

// MARK: - Private

private extension OnrampRedirectingViewModel {
    func makeOnrampRedirectSettings() -> OnrampRedirectSettings {
        let theme: OnrampRedirectSettings.Theme = {
            switch colorScheme {
            case .light: .light
            case .dark: .dark
            @unknown default: .light
            }
        }()

        // We don't use `Locale.current.languageCode`
        // Because it gives us the phone language not app
        let appLanguageCode = Bundle.main.preferredLocalizations[0]

        return OnrampRedirectSettings(
            successURL: IncomingActionConstants.externalSuccessURL,
            theme: theme,
            language: appLanguageCode
        )
    }

    func logOpening() {
        guard let provider = interactor.onrampProvider,
              let request = try? provider.makeOnrampQuotesRequestItem() else {
            return
        }

        Analytics.log(
            event: .onrampButtonBuy,
            params: [
                .provider: provider.provider.name,
                .currency: request.pairItem.fiatCurrency.identity.code,
                .token: tokenItem.currencySymbol,
            ]
        )
    }
}
