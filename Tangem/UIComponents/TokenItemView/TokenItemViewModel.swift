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
    @Published var priceChangeState: TokenPriceChangeView.State = .loading
    @Published var hasPendingTransactions: Bool = false

    @Published private var missingDerivation: Bool = false
    @Published private var networkUnreachable: Bool = false

    var name: String { tokenIcon.name }
    var imageURL: URL? { tokenIcon.imageURL }
    var blockchainIconName: String? { tokenIcon.blockchainIconName }
    var hasMonochromeIcon: Bool { networkUnreachable || missingDerivation || isTestnetToken }
    var isCustom: Bool { tokenIcon.isCustom }

    var hasError: Bool { missingDerivation || networkUnreachable }
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

    private var percentFormatter = PercentFormatter()
    private var bag = Set<AnyCancellable>()

    init(
        id: Int,
        tokenIcon: TokenIconInfo,
        isTestnetToken: Bool,
        infoProvider: TokenItemInfoProvider,
        tokenTapped: @escaping (WalletModelId) -> Void
    ) {
        self.id = id
        self.tokenIcon = tokenIcon
        self.isTestnetToken = isTestnetToken
        self.infoProvider = infoProvider
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
                    updatePriceChange()
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
                    updatePriceChange()
                case .loading:
                    break
                }

                updatePendingTransactionsStateIfNeeded()
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

    private func updatePriceChange() {
        guard let quote = infoProvider.quote else {
            priceChangeState = .noData
            return
        }

        let signType = ChangeSignType(from: quote.change)

        let percent = percentFormatter.percentFormat(value: quote.change)
        priceChangeState = .loaded(signType: signType, text: percent)
    }
}
