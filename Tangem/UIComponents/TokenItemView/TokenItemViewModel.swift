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
    var hasMonochromeIcon: Bool { networkUnreachable || missingDerivation || isTestnetToken }
    var errorMessage: String? {
        // Don't forget to add check in trailing item in `TokenItemView` when adding new error here
        if missingDerivation {
            return Localization.commonNoAddress
        }

        if networkUnreachable {
            return Localization.commonUnreachable
        }

        return nil
    }

    private let tokenIcon: TokenIconInfo
    private let isTestnetToken: Bool
    private let tokenTapped: (WalletModelId) -> Void
    private let infoProvider: TokenItemInfoProvider
    private let priceChangeProvider: PriceChangeProvider

    private var bag = Set<AnyCancellable>()

    init(
        id: Int,
        tokenIcon: TokenIconInfo,
        isTestnetToken: Bool,
        infoProvider: TokenItemInfoProvider,
        priceChangeProvider: PriceChangeProvider,
        tokenTapped: @escaping (WalletModelId) -> Void
    ) {
        self.id = id
        self.tokenIcon = tokenIcon
        self.isTestnetToken = isTestnetToken
        self.infoProvider = infoProvider
        self.priceChangeProvider = priceChangeProvider
        self.tokenTapped = tokenTapped

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
                case .notLoaded:
                    missingDerivation = false
                    networkUnreachable = false
                case .loaded, .noAccount:
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
