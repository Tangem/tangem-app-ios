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

    private let tokenIcon: TokenIconInfo
    private let amountType: Amount.AmountType
    private let tokenTapped: (WalletModelId) -> Void
    private unowned let infoProvider: TokenItemInfoProvider
    private unowned let priceChangeProvider: PriceChangeProvider

    private let cryptoFormattingOptions: BalanceFormattingOptions
    private var fiatFormattingOptions: BalanceFormattingOptions {
        .defaultFiatFormattingOptions
    }

    private var bag = Set<AnyCancellable>()
    private var balanceUpdateTask: Task<Void, Error>?

    init(
        id: Int,
        tokenIcon: TokenIconInfo,
        amountType: Amount.AmountType,
        tokenTapped: @escaping (WalletModelId) -> Void,
        infoProvider: TokenItemInfoProvider,
        priceChangeProvider: PriceChangeProvider,
        cryptoFormattingOptions: BalanceFormattingOptions
    ) {
        self.id = id
        self.tokenIcon = tokenIcon
        self.amountType = amountType
        self.tokenTapped = tokenTapped
        self.infoProvider = infoProvider
        self.priceChangeProvider = priceChangeProvider
        self.cryptoFormattingOptions = cryptoFormattingOptions

        bind()
    }

    func tapAction() {
        tokenTapped(id)
    }

    private func bind() {
        infoProvider.walletStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                guard let self else { return }

                switch newState {
                case .noDerivation:
                    missingDerivation = true
                    networkUnreachable = false
                case .failed:
                    missingDerivation = false
                    networkUnreachable = true
                case .noAccount(let message):
                    balanceCrypto = .loaded(text: message)
                    fallthrough
                case .created:
                    missingDerivation = false
                    networkUnreachable = false
                case .idle:
                    missingDerivation = false
                    networkUnreachable = false
                    updateBalances()
                case .loading:
                    break
                }
            }
            .store(in: &bag)

        infoProvider.pendingTransactionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] id, hasPendingTransactions in
                guard self?.id == id else {
                    return
                }

                self?.hasPendingTransactions = hasPendingTransactions
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

    private func updateBalances() {
        let formatter = BalanceFormatter()
        let balance = infoProvider.balance(for: amountType)
        let formattedBalance = formatter.formatCryptoBalance(balance, formattingOptions: cryptoFormattingOptions)
        balanceCrypto = .loaded(text: formattedBalance)

        balanceUpdateTask?.cancel()
        balanceUpdateTask = Task { [weak self] in
            guard let self else { return }

            let formattedFiat: String
            do {
                let fiatBalance = try await BalanceConverter().convertToFiat(
                    value: balance,
                    from: cryptoFormattingOptions.currencyCode,
                    to: fiatFormattingOptions.currencyCode
                )
                formattedFiat = formatter.formatFiatBalance(fiatBalance, formattingOptions: fiatFormattingOptions)
            } catch {
                formattedFiat = "-"
            }

            try Task.checkCancellation()
            await MainActor.run {
                self.balanceFiat = .loaded(text: formattedFiat)
            }
        }
    }
}
