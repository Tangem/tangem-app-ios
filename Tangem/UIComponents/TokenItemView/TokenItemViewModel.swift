//
//  TokenItemViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 28/04/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

typealias WalletModelId = Int

final class TokenItemViewModel: ObservableObject, Identifiable {
    let id: WalletModelId

    @Published var balanceCrypto: LoadableTextView.State = .loading
    @Published var balanceFiat: LoadableTextView.State = .loading
    @Published var changePercentage: LoadableTextView.State = .noData
    @Published var missingDerivation: Bool = false
    @Published var networkUnreachable: Bool = false
    @Published var hasPendingTransactions: Bool = false

    var name: String { tokenIcon.name }
    var imageURL: URL? { tokenIcon.imageURL }
    var blockchainIconName: String? { tokenIcon.blockchainIconName }
    var isColorlessIcon: Bool { networkUnreachable || missingDerivation || tokenItem.blockchain.isTestnet }
    var trailingErrorMessage: String? {
        if missingDerivation {
            return Localization.commonNoAddress
        }

        if networkUnreachable {
            return Localization.commonUnreachable
        }

        return nil
    }

    private let tokenIcon: TokenIconInfo
    private let tokenItem: TokenItem
    private let tokenTapped: (WalletModelId) -> Void
    private unowned let infoProvider: TokenItemInfoProvider
    private unowned let priceChangeProvider: PriceChangeProvider

    private var bag = Set<AnyCancellable>()

    init(
        id: Int,
        tokenIcon: TokenIconInfo,
        tokenItem: TokenItem,
        tokenTapped: @escaping (WalletModelId) -> Void,
        infoProvider: TokenItemInfoProvider,
        priceChangeProvider: PriceChangeProvider
    ) {
        self.id = id
        self.tokenIcon = tokenIcon
        self.tokenItem = tokenItem
        self.tokenTapped = tokenTapped
        self.infoProvider = infoProvider
        self.priceChangeProvider = priceChangeProvider

        bind()
    }

    func tapAction() {
        tokenTapped(id)
    }

    private func bind() {
        infoProvider.tokenItemStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                guard let self else { return }

                switch newState {
                case .noDerivation:
                    missingDerivation = true
                    networkUnreachable = false
                    updateBalances()
                case .networkError:
                    missingDerivation = false
                    networkUnreachable = true
                case .noAccount(let message):
                    balanceCrypto = .loaded(text: message)
                    fallthrough
                case .notLoaded:
                    missingDerivation = false
                    networkUnreachable = false
                case .loaded:
                    missingDerivation = false
                    networkUnreachable = false
                    updateBalances()
                case .loading:
                    break
                }

                updatePendingTransactionsStateIfNeeded()
            }
            .store(in: &bag)

        priceChangeProvider.priceChangePublisher
            .receive(on: DispatchQueue.main)
            .compactMap { [weak self] _ -> String? in
                guard let self else { return nil }

                // TODO: https://tangem.atlassian.net/browse/IOS-3525
                // An API has not been provided and also not all states was described in design.
                // To be added after implementation on the backend and design update
                return " "
            }
            .sink { [weak self] priceChange in
                self?.changePercentage = .loaded(text: priceChange)
            }
            .store(in: &bag)
    }

    private func updatePendingTransactionsStateIfNeeded() {
        hasPendingTransactions = infoProvider.hasPendingTransactions
    }

    private func updateBalances() {
        balanceCrypto = .loaded(text: infoProvider.balance)
        balanceFiat = .loaded(text: infoProvider.fiatBalance)
    }
}
