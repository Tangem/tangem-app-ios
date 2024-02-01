//
//  VisaWalletModel.swift
//  Tangem
//
//  Created by Andrew Son on 18/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemVisa

class VisaWalletModel {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository
    @Injected(\.keysManager) private var keysManager: KeysManager

    private let transactionHistoryService: VisaTransactionHistoryService
    private var visaBridgeInteractor: VisaBridgeInteractor?

    var accountAddress: String { visaBridgeInteractor?.accountAddress ?? .unknown }

    var walletDidChangePublisher: AnyPublisher<State, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var balancesPublisher: AnyPublisher<AppVisaBalances?, Never> {
        balancesSubject.eraseToAnyPublisher()
    }

    var limitsPublisher: AnyPublisher<AppVisaLimits?, Never> {
        limitsSubject.eraseToAnyPublisher()
    }

    var balances: AppVisaBalances? {
        balancesSubject.value
    }

    var limits: AppVisaLimits? {
        limitsSubject.value
    }

    var transactionHistoryStatePublisher: AnyPublisher<TransactionHistoryServiceState, Never> {
        transactionHistoryService.statePublisher
    }

    var transactionHistoryItems: [TransactionListItem] {
        let historyMapper = VisaTransactionHistoryMapper(currencySymbol: tokenItem.currencySymbol)
        return historyMapper.mapTransactionListItem(from: transactionHistoryService.items)
    }

    var canFetchMoreTransactionHistory: Bool {
        transactionHistoryService.canFetchMoreHistory
    }

    let tokenItem: TokenItem

    private let userWalletModel: UserWalletModel

    private let balancesSubject = CurrentValueSubject<AppVisaBalances?, Never>(nil)
    private let limitsSubject = CurrentValueSubject<AppVisaLimits?, Never>(nil)
    private let stateSubject = CurrentValueSubject<State, Never>(.notInitialized)

    private var updateTask: Task<Void, Never>?
    private var historyReloadTask: Task<Void, Never>?

    init(userWalletModel: UserWalletModel) {
        self.userWalletModel = userWalletModel
        let utils = VisaUtilities()
        tokenItem = .token(utils.visaToken, utils.visaBlockchain)

        let apiService = VisaAPIServiceBuilder().build(
            isTestnet: true,
            urlSessionConfiguration: .defaultConfiguration,
            logger: AppLog.shared
        )
        let cardPublicKey: String
        if let wallet = userWalletModel.userWallet.card.wallets.first(where: { $0.curve == .secp256k1 }) {
            cardPublicKey = wallet.publicKey.hexString
        } else {
            cardPublicKey = "Failed to find secp256k1 key"
        }

        transactionHistoryService = VisaTransactionHistoryService(
            cardPublicKey: cardPublicKey,
            apiService: apiService
        )

        setupBridgeInteractor()
    }

    func exploreURL() -> URL? {
        let linkProvider = ExternalLinkProviderFactory().makeProvider(for: tokenItem.blockchain)
        return linkProvider.url(address: accountAddress, contractAddress: tokenItem.token?.contractAddress)
    }

    func transaction(with id: UInt64) -> VisaTransactionRecord? {
        transactionHistoryService.items.first(where: { $0.id == id })
    }

    func generalUpdateAsync() async {
        if visaBridgeInteractor == nil {
            await setupBridgeInteractorAsync()
            return
        }

        await withTaskGroup(of: Void.self) { [weak self] group in
            guard let self else { return }

            stateSubject.send(.loading)
            group.addTask {
                guard let currencyId = self.tokenItem.currencyId else {
                    return
                }

                await self.quotesRepository.loadQuotes(currencyIds: [currencyId])
            }

            group.addTask { await self.loadBalancesAndLimits() }

            group.addTask { await self.reloadHistoryAsync() }

            await group.waitForAll()
            stateSubject.send(.idle)
        }
    }

    func reloadHistory() {
        guard historyReloadTask == nil else {
            return
        }

        historyReloadTask = Task { [weak self] in
            await self?.reloadHistoryAsync()
            self?.historyReloadTask = nil
        }
    }

    func loadNextHistoryPage() {
        guard historyReloadTask == nil else {
            return
        }

        historyReloadTask = Task { [weak self] in
            await self?.transactionHistoryService.loadNextPage()
            self?.historyReloadTask = nil
        }
    }

    private func setupBridgeInteractor() {
        Task { [weak self] in
            await self?.setupBridgeInteractorAsync()
        }
    }

    private func setupBridgeInteractorAsync() async {
        guard let walletModel = userWalletModel.walletModelsManager.walletModels.first(where: {
            $0.tokenItem == tokenItem
        }) else {
            stateSubject.send(.failedToInitialize(.missingRequiredBlockchain))
            return
        }

        stateSubject.send(.loading)
        let smartContractInteractor: EVMSmartContractInteractor
        do {
            let factory = EVMSmartContractInteractorFactory(config: keysManager.blockchainConfig)
            smartContractInteractor = try factory.makeInteractor(for: tokenItem.blockchain)
        } catch {
            stateSubject.send(.failedToInitialize(.invalidBlockchain))
            return
        }

        let builder = VisaBridgeInteractorBuilder(evmSmartContractInteractor: smartContractInteractor)
        do {
            let interactor = try await builder.build(for: walletModel.defaultAddress, logger: AppLog.shared)
            visaBridgeInteractor = interactor
            await generalUpdateAsync()
        } catch {
            stateSubject.send(.failedToInitialize(.noPaymentAccount))
        }
    }

    private func updateBalanceAndLimits() {
        Task { [weak self] in
            await self?.loadBalancesAndLimits()
        }
    }

    private func loadBalancesAndLimits() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in await self?.updateBalances() }
            group.addTask { [weak self] in await self?.updateLimits() }

            await group.waitForAll()
        }
    }

    private func updateBalances() async {
        guard let visaBridgeInteractor else {
            return
        }

        do {
            let balances = try await visaBridgeInteractor.loadBalances()
            balancesSubject.send(.init(balances: balances))
        } catch {
            balancesSubject.send(nil)
        }
    }

    private func updateLimits() async {
        guard let visaBridgeInteractor else {
            return
        }

        do {
            let limits = try await visaBridgeInteractor.loadLimits()
            limitsSubject.send(.init(limits: limits))
        } catch {
            limitsSubject.send(nil)
        }
    }

    private func reloadHistoryAsync() async {
        await transactionHistoryService.reloadHistory()
    }

    private func log(_ message: @autoclosure () -> String) {
        AppLog.shared.debug("\n\n[VisaWalletModel] \(message())\n\n")
    }
}

extension VisaWalletModel: VisaWalletMainHeaderSubtitleDataSource {
    var fiatBalance: String {
        BalanceFormatter().formatFiatBalance(fiatValue)
    }

    var blockchainName: String {
        "Polygon PoS"
    }

    private var fiatValue: Decimal? {
        guard
            let balanceValue = balancesSubject.value?.available,
            let currencyId = tokenItem.currencyId
        else {
            return nil
        }

        let converter = BalanceConverter()
        return converter.convertToFiat(value: balanceValue, from: currencyId)
    }
}

extension VisaWalletModel: MainHeaderBalanceProvider {
    var balanceProvider: AnyPublisher<LoadingValue<NSAttributedString>, Never> {
        stateSubject.combineLatest(balancesSubject)
            .map { [weak self] state, balances -> LoadingValue<NSAttributedString> in
                guard let self else {
                    return .loading
                }

                switch state {
                case .notInitialized, .loading:
                    return .loading
                case .failedToInitialize(let error):
                    return .failedToLoad(error: error)
                case .idle:
                    if let balances {
                        let balanceFormatter = BalanceFormatter()
                        let formattedBalance = balanceFormatter.formatCryptoBalance(balances.available, currencyCode: tokenItem.currencySymbol)
                        let formattedForMain = balanceFormatter.formatTotalBalanceForMain(fiatBalance: formattedBalance, formattingOptions: .defaultOptions)
                        return .loaded(formattedForMain)
                    } else {
                        return .loading
                    }
                }
            }
            .eraseToAnyPublisher()
    }
}

extension VisaWalletModel {
    enum State: Hashable {
        case notInitialized
        case loading
        case failedToInitialize(ModelError)
        case idle
    }

    enum ModelError: Error, Hashable {
        case missingRequiredBlockchain
        case invalidBlockchain
        case noPaymentAccount

        var notificationEvent: VisaNotificationEvent {
            switch self {
            case .missingRequiredBlockchain: return .missingRequiredBlockchain
            case .invalidBlockchain: return .notValidBlockchain
            case .noPaymentAccount: return .failedToLoadPaymentAccount
            }
        }
    }
}
