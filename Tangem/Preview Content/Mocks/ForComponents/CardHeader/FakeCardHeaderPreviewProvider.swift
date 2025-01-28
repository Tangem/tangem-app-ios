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
                let firstValue: Decimal = 4346824.2189
                let secondValue: Decimal = 4346820004.2189
                let thirdValue: Decimal = 4346213820004.2189
                let fourthValue: Decimal? = nil
                switch provider.balance {
                case .loading:
                    provider.balance = .loaded(balance: firstValue)
                case .empty:
                    provider.balance = .loaded(balance: firstValue)
                case .loaded(let total):
                    let newValue: Decimal?
                    switch total {
                    case firstValue:
                        newValue = secondValue
                    case secondValue:
                        newValue = thirdValue
                    case thirdValue:
                        newValue = fourthValue
                    default:
                        newValue = firstValue
                    }
                    provider.balance = newValue.map { .loaded(balance: $0) } ?? .empty
                case .failed:
                    provider.balance = .loading(cached: .none)
                }
            }
        ),
        CardInfoProvider(
            walletModel: FakeUserWalletModel.twins,
            tapAction: { provider in
                provider.walletModel.updateWalletName(provider.walletModel.userWalletName == "Wallet Hannah" ? "Wallet Jane" : "Wallet Hannah")
                switch provider.balance {
                case .loading:
                    provider.balance = .loaded(balance: 92324.2133654889)
                case .empty, .loaded, .failed:
                    provider.balance = .loading(cached: .none)
                }
            }
        ),
        CardInfoProvider(
            walletModel: FakeUserWalletModel.xrpNote,
            tapAction: { provider in
                switch provider.balance {
                case .loading:
                    provider.balance = .loaded(balance: 4567575476468896456534878754.2114313)
                case .empty, .loaded, .failed:
                    provider.balance = .loading(cached: .none)
                }
            }
        ),
        CardInfoProvider(
            walletModel: FakeUserWalletModel.xlmBird,
            tapAction: { provider in
                switch provider.balance {
                case .loading:
                    provider.balance = .loaded(balance: 4567575476468896456532344878754.2114313)
                case .empty, .loaded, .failed:
                    provider.balance = .loading(cached: .none)
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
                    isUserWalletLocked: $0.walletModel.isUserWalletLocked,
                    supplementInfoProvider: $0.walletModel,
                    subtitleProvider: $0.headerSubtitleProvider,
                    balanceProvider: CommonMainHeaderBalanceProvider(
                        totalBalanceProvider: $0,
                        userWalletStateInfoProvider: $0.walletModel,
                        mainBalanceFormatter: CommonMainHeaderBalanceFormatter()
                    )
                )
            }
    }
}

extension FakeCardHeaderPreviewProvider {
    final class CardInfoProvider: TotalBalanceProviding {
        @Published var balance: TotalBalanceState = .loading(cached: .none)

        let walletModel: FakeUserWalletModel
        let headerSubtitleProvider: MainHeaderSubtitleProvider

        var tapAction: (CardInfoProvider) -> Void

        init(walletModel: FakeUserWalletModel, tapAction: @escaping (CardInfoProvider) -> Void) {
            self.walletModel = walletModel
            headerSubtitleProvider = CommonMainHeaderProviderFactory()
                .makeHeaderSubtitleProvider(for: walletModel, isMultiWallet: walletModel.config.hasFeature(.multiCurrency))
            self.tapAction = tapAction
        }

        var totalBalancePublisher: AnyPublisher<TotalBalanceState, Never> {
            $balance.eraseToAnyPublisher()
        }
    }
}
