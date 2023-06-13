//
//  LegacyMultiWalletContentViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.09.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

protocol LegacyMultiWalletContentViewModelOutput: OpenCurrencySelectionDelegate {
    func openTokenDetails(_ tokenItem: LegacyTokenItemViewModel)
    func openTokensList()
}

class LegacyMultiWalletContentViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var contentState: LoadingValue<[LegacyTokenItemViewModel]> = .loading
    @Published var tokenListIsEmpty: Bool = true

    lazy var totalSumBalanceViewModel = TotalSumBalanceViewModel(
        userWalletModel: cardModel,
        cardAmountType: nil,
        tapOnCurrencySymbol: output
    )

    // MARK: Private

    private unowned let output: LegacyMultiWalletContentViewModelOutput

    private let cardModel: CardViewModel
    private let userTokenListManager: UserTokenListManager
    private var bag = Set<AnyCancellable>()

    init(
        cardModel: CardViewModel,
        userTokenListManager: UserTokenListManager,
        output: LegacyMultiWalletContentViewModelOutput
    ) {
        self.cardModel = cardModel
        self.userTokenListManager = userTokenListManager
        self.output = output

        tokenListIsEmpty = cardModel.getSavedEntries().isEmpty
        bind()

        cardModel.updateWalletModels()
    }

    func onRefresh(silent: Bool = true, done: @escaping () -> Void) {
        if cardModel.hasTokenSynchronization {
            userTokenListManager.updateLocalRepositoryFromServer { [weak self] _ in
                self?.cardModel.updateAndReloadWalletModels(silent: silent, completion: done)
            }
        } else {
            cardModel.updateAndReloadWalletModels(silent: silent, completion: done)
        }
    }

    func openTokensList() {
        Analytics.log(.buttonManageTokens)
        output.openTokensList()
    }

    func tokenItemDidTap(_ itemViewModel: LegacyTokenItemViewModel) {
        output.openTokenDetails(itemViewModel)
    }
}

// MARK: - Private

private extension LegacyMultiWalletContentViewModel {
    func bind() {
        /// Subscribe for update wallets for each changes in `WalletModel`
        cardModel.subscribeToWalletModels()
            .flatMap { walletModels in
                Publishers
                    .MergeMany(walletModels.map { $0.walletDidChange })
                    .filter { !$0.isLoading }
            }
            .receive(on: DispatchQueue.global())
            .map { [weak self] _ -> [LegacyTokenItemViewModel] in
                self?.collectTokenItemViewModels() ?? []
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] viewModels in
                self?.updateView(viewModels: viewModels)
            }
            .store(in: &bag)

        let entriesWithoutDerivation = cardModel
            .subscribeToEntriesWithoutDerivation()
            .dropFirst()
            .removeDuplicates()

        let newWalletModels = cardModel.subscribeToWalletModels()
            .dropFirst()

        Publishers.Merge(
            newWalletModels.mapVoid(),
            entriesWithoutDerivation.mapVoid()
        )
        .receive(on: DispatchQueue.global())
        .map { [weak self] _ -> [LegacyTokenItemViewModel] in
            /// `unowned` will be crashed when the wallet which currently open is deleted from the list of saved wallet
            self?.collectTokenItemViewModels() ?? []
        }
        .removeDuplicates()
        .receive(on: RunLoop.main)
        .sink { [weak self] viewModels in
            self?.updateView(viewModels: viewModels)
        }
        .store(in: &bag)
    }

    func updateView(viewModels: [LegacyTokenItemViewModel]) {
        if tokenListIsEmpty != viewModels.isEmpty {
            tokenListIsEmpty = viewModels.isEmpty
        }

        contentState = .loaded(viewModels)
    }

    func collectTokenItemViewModels() -> [LegacyTokenItemViewModel] {
        let entries = cardModel.getSavedEntries()
        let walletModels = cardModel.walletModels
        return entries.reduce([]) { result, entry in
            if let walletModel = walletModels.first(where: { $0.blockchainNetwork == entry.blockchainNetwork }) {
                return result + walletModel.legacyMultiCurrencyViewModel()
            }

            return result + mapToTokenItemViewModels(entry: entry)
        }
    }

    func mapToTokenItemViewModels(entry: StorageEntry) -> [LegacyTokenItemViewModel] {
        let network = entry.blockchainNetwork
        var items: [LegacyTokenItemViewModel] = [
            LegacyTokenItemViewModel(
                state: .noDerivation,
                name: network.blockchain.displayName,
                blockchainNetwork: network,
                amountType: .coin,
                isCustom: false
            ),
        ]

        items += entry.tokens.map { token in
            LegacyTokenItemViewModel(
                state: .noDerivation,
                name: token.name,
                blockchainNetwork: network,
                amountType: .token(value: token),
                isCustom: token.isCustom
            )
        }

        return items
    }
}
