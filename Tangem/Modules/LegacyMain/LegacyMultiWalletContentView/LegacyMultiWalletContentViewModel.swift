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

    var totalSumBalanceViewModel: TotalSumBalanceViewModel

    // MARK: Private

    private unowned let output: LegacyMultiWalletContentViewModelOutput

    private let userTokenListManager: UserTokenListManager
    private let walletModelsManager: WalletModelsManager
    private let updateQueue = DispatchQueue(label: "multi_wallet_content_update_queue", qos: .default)
    private var bag = Set<AnyCancellable>()

    init(
        walletModelsManager: WalletModelsManager,
        userTokenListManager: UserTokenListManager,
        totalBalanceProvider: TotalBalanceProviding,
        output: LegacyMultiWalletContentViewModelOutput
    ) {
        self.walletModelsManager = walletModelsManager
        self.userTokenListManager = userTokenListManager
        self.output = output
        totalSumBalanceViewModel = .init(
            totalBalanceProvider: totalBalanceProvider,
            walletModelsManager: walletModelsManager,
            tapOnCurrencySymbol: output
        )
        tokenListIsEmpty = walletModelsManager.walletModels.isEmpty
        bind()
    }

    func onRefresh(silent: Bool = true, done: @escaping () -> Void) {
        userTokenListManager.updateLocalRepositoryFromServer { [weak self] _ in
            self?.walletModelsManager.updateAll(silent: silent, completion: done)
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
        walletModelsManager
            .walletModelsPublisher
            .flatMap { walletModels in
                Publishers
                    .MergeMany(walletModels.map { $0.walletDidChangePublisher })
            }
            .receive(on: updateQueue)
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .map { [weak self] _ -> [LegacyTokenItemViewModel] in
                self?.collectTokenItemViewModels() ?? []
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] viewModels in
                self?.updateView(viewModels: viewModels)
            }
            .store(in: &bag)

        walletModelsManager.walletModelsPublisher
            .combineLatest(userTokenListManager.userTokensPublisher)
            .receive(on: updateQueue)
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
        let storageEntries = userTokenListManager.userTokens
        let storageEntriesGroupedByBlockchainNetworks = Dictionary(grouping: storageEntries, by: \.blockchainNetwork)
        let blockchainNetworksFromStorageEntries = storageEntries
            .unique(by: \.blockchainNetwork)
            .map(\.blockchainNetwork)

        let walletModelsKeyedByIds = walletModelsManager
            .walletModels
            .keyedFirst(by: \.id)

        let blockchainNetworksFromWalletModels = walletModelsKeyedByIds
            .values
            .unique(by: \.blockchainNetwork)
            .map(\.blockchainNetwork)
            .toSet()

        return blockchainNetworksFromStorageEntries.reduce(into: []) { partialResult, element in
            guard let storageEntries = storageEntriesGroupedByBlockchainNetworks[element] else { return }

            if blockchainNetworksFromWalletModels.contains(element) {
                partialResult += storageEntries
                    .compactMap { walletModelsKeyedByIds[$0.walletModelId] }
                    .map { mapToTokenItemViewModel($0) }
            } else {
                partialResult += mapToTokenItemViewModels(storageEntries)
            }
        }
    }

    func mapToTokenItemViewModel(_ walletModel: WalletModel) -> LegacyTokenItemViewModel {
        LegacyTokenItemViewModel(
            state: walletModel.state,
            name: walletModel.name,
            balance: walletModel.balance,
            fiatBalance: walletModel.fiatBalance,
            rate: walletModel.rateFormatted,
            fiatValue: walletModel.fiatValue ?? 0,
            blockchainNetwork: walletModel.blockchainNetwork,
            amountType: walletModel.amountType,
            hasTransactionInProgress: walletModel.isMainToken ? walletModel.hasPendingTransactions : false,
            isCustom: walletModel.isCustom
        )
    }

    func mapToTokenItemViewModels(_ storageEntries: [StorageEntry.V3.Entry]) -> [LegacyTokenItemViewModel] {
        let converter = StorageEntriesConverter()

        return storageEntries.map { storageEntry in
            let blockchainNetwork = storageEntry.blockchainNetwork

            if let token = converter.convertToToken(storageEntry) {
                return LegacyTokenItemViewModel(
                    state: .noDerivation,
                    name: token.name,
                    blockchainNetwork: blockchainNetwork,
                    amountType: .token(value: token),
                    isCustom: token.isCustom
                )
            }

            return LegacyTokenItemViewModel(
                state: .noDerivation,
                name: blockchainNetwork.blockchain.displayName,
                blockchainNetwork: blockchainNetwork,
                amountType: .coin,
                isCustom: false
            )
        }
    }
}
