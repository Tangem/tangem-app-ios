//
//  FakeCardHeaderPreviewProvider.swift
//  Tangem
//
//  Created by Andrew Son on 12/05/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class FakeCardHeaderPreviewProvider: ObservableObject {
    @Published var models: [MainHeaderViewModel] = []

    let infoProviders: [CardInfoProvider] = [
        CardInfoProvider(
            walletModel: FakeUserWalletModel.wallet3Cards,
            tapAction: { provider in
                provider.walletModel.updateWalletName(provider.walletModel.userWalletName == "William Wallet" ? "Uilleam Uallet" : "William Wallet")
                switch provider.balance {
                case .loading:
                    provider.balance = .loaded(TotalBalanceProvider.TotalBalance(
                        balance: 4346437892534324.2189,
                        currencyCode: "USD",
                        hasError: false
                    ))
                case .loaded, .failedToLoad:
                    provider.balance = .loading
                }
            }
        ),
        CardInfoProvider(
            walletModel: FakeUserWalletModel.twins,
            tapAction: { provider in
                provider.walletModel.updateWalletName(provider.walletModel.userWalletName == "Wallet Hannah" ? "Wallet Jane" : "Wallet Hannah")
                switch provider.balance {
                case .loading:
                    provider.balance = .loaded(TotalBalanceProvider.TotalBalance(
                        balance: 92324.2133654889,
                        currencyCode: "EUR",
                        hasError: false
                    ))
                case .loaded, .failedToLoad:
                    provider.balance = .loading
                }
            }
        ),
        CardInfoProvider(
            walletModel: FakeUserWalletModel.xrpNote,
            tapAction: { provider in
                switch provider.balance {
                case .loading:
                    provider.balance = .loaded(TotalBalanceProvider.TotalBalance(
                        balance: 4567575476468896456534878754.2114313,
                        currencyCode: "USD",
                        hasError: false
                    ))
                case .loaded, .failedToLoad:
                    provider.balance = .loading
                }
            }
        ),
    ]

    init() {
        initializeModels()
    }

    private func initializeModels() {
        models = infoProviders
            .map {
                .init(
                    infoProvider: $0.walletModel,
                    subtitleProvider: $0.headerSubtitleProvider,
                    balanceProvider: $0
                )
            }
    }
}

extension FakeCardHeaderPreviewProvider {
    final class CardInfoProvider: TotalBalanceProviding {
        @Published var balance: LoadingValue<TotalBalanceProvider.TotalBalance> = .loading

        let walletModel: FakeUserWalletModel
        let headerSubtitleProvider: MainHeaderSubtitleProvider

        var tapAction: (CardInfoProvider) -> Void

        init(walletModel: FakeUserWalletModel, tapAction: @escaping (CardInfoProvider) -> Void) {
            self.walletModel = walletModel
            headerSubtitleProvider = MainHeaderSubtitleProviderFactory().provider(for: walletModel, isMultiWallet: false)
            self.tapAction = tapAction
        }

        func totalBalancePublisher() -> AnyPublisher<LoadingValue<TotalBalanceProvider.TotalBalance>, Never> {
            $balance.eraseToAnyPublisher()
        }
    }
}
