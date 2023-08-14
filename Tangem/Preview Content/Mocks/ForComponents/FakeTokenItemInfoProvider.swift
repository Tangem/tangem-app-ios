//
//  FakeTokenItemInfoProvider.swift
//  Tangem
//
//  Created by Andrew Son on 27/04/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class FakeTokenItemInfoProvider: PriceChangeProvider, ObservableObject {
    var priceChangePublisher: AnyPublisher<Void, Never> { priceChangedSubject.eraseToAnyPublisher() }

    let pendingTransactionNotifier = PassthroughSubject<(WalletModelId, Bool), Never>()

    let priceChangedSubject = PassthroughSubject<Void, Never>()

    private var amountsIndex = 0
    private var previouslyTappedModelId: Int?
    private var bag = Set<AnyCancellable>()

    var hasPendingTransactions: Bool { false }

    private(set) var viewModels: [TokenItemViewModel] = []

    private var walletModels: [WalletModel] = []

    init(walletManagers: [FakeWalletManager]) {
        walletModels = walletManagers.flatMap { $0.walletModels }
        viewModels = walletModels.map {
            TokenItemViewModel(
                id: $0.id,
                tokenIcon: makeTokenIconInfo(for: $0),
                tokenItem: makeTokenItem(for: $0),
                tokenTapped: modelTapped(with:),
                infoProvider: DefaultTokenItemInfoProvider(walletModel: $0),
                priceChangeProvider: self
            )
        }
    }

    func change(for currencyCode: String, in blockchain: BlockchainSdk.Blockchain) -> Double {
        0
    }

    func modelTapped(with id: Int) {
        guard let tappedWalletManager = walletModels.first(where: { $0.id == id }) else {
            return
        }
        print("Tapped wallet model: \(tappedWalletManager)")
        var updateSubscription: AnyCancellable?
        updateSubscription = tappedWalletManager.update(silent: true)
            .sink { newState in
                print("Receive new state \(newState) for \(tappedWalletManager)")
                withExtendedLifetime(updateSubscription) {}
            }
    }

    private func makeTokenIconInfo(for walletModel: WalletModel) -> TokenIconInfo {
        return TokenIconInfoBuilder()
            .build(
                for: walletModel.tokenItem.amountType,
                in: walletModel.blockchainNetwork.blockchain
            )
    }

    private func makeTokenItem(for walletModel: WalletModel) -> TokenItem {
        let blockchain = walletModel.blockchainNetwork.blockchain
        switch walletModel.amountType {
        case .coin, .reserve: return .blockchain(blockchain)
        case .token(let value): return .token(value, blockchain)
        }
    }
}
