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
    @Injected(\.apiListProvider) private var apiListProvider: APIListProvider

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
        let historyMapper = VisaTransactionHistoryMapper(currencySymbol: currencySymbol)
        return historyMapper.mapTransactionListItem(from: transactionHistoryService.items)
    }

    var canFetchMoreTransactionHistory: Bool {
        transactionHistoryService.canFetchMoreHistory
    }

    var currencySymbol: String {
        tokenItem?.currencySymbol ?? "Not loaded"
    }

    var tokenItem: TokenItem?

    private let userWalletModel: UserWalletModel

    private let balancesSubject = CurrentValueSubject<AppVisaBalances?, Never>(nil)
    private let limitsSubject = CurrentValueSubject<AppVisaLimits?, Never>(nil)
    private let stateSubject = CurrentValueSubject<State, Never>(.notInitialized)

    private var updateTask: Task<Void, Never>?
    private var historyReloadTask: Task<Void, Never>?

    init(userWalletModel: UserWalletModel) {
        self.userWalletModel = userWalletModel

        let apiService = VisaAPIServiceBuilder().buildTransactionHistoryService(
            isTestnet: FeatureStorage.instance.isVisaTestnet,
            urlSessionConfiguration: .defaultConfiguration,
            logger: AppLog.shared
        )
        let cardPublicKey: String
        if let publicKey = VisaAppUtilities().getPublicKeyData(from: userWalletModel.keysRepository.keys) {
            cardPublicKey = publicKey.hexString
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
        let linkProvider = ExternalLinkProviderFactory().makeProvider(for: VisaUtilities().visaBlockchain)
        return linkProvider.url(address: accountAddress, contractAddress: tokenItem?.token?.contractAddress)
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
                guard let currencyId = self.tokenItem?.currencyId else {
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
        stateSubject.send(.loading)

        let blockchain = VisaUtilities().visaBlockchain
        let factory = EVMSmartContractInteractorFactory(config: keysManager.blockchainConfig)

        let smartContractInteractor: EVMSmartContractInteractor
        do {
            let apiList = try await apiListProvider.apiListPublisher.async()
            smartContractInteractor = try factory.makeInteractor(for: blockchain, apiInfo: apiList[blockchain.networkId] ?? [])
        } catch {
            log("Failed to setup bridge. Error: \(error)")
            stateSubject.send(.failedToInitialize(.invalidBlockchain))
            return
        }

        let appUtilities = VisaAppUtilities()
        guard let walletPublicKey = appUtilities.makeBlockchainKey(using: userWalletModel.keysRepository.keys) else {
            stateSubject.send(.failedToInitialize(.failedToGenerateAddress))
            return
        }

        do {
            let address = try AddressServiceFactory(blockchain: blockchain)
                .makeAddressService()
                .makeAddress(for: walletPublicKey, with: .default)
            let builder = VisaBridgeInteractorBuilder(isTestnet: blockchain.isTestnet, evmSmartContractInteractor: smartContractInteractor, logger: AppLog.shared)
            let interactor = try await builder.build(for: address.value)
            visaBridgeInteractor = interactor
            tokenItem = .token(interactor.visaToken, .init(blockchain, derivationPath: nil))
            await generalUpdateAsync()
        } catch {
            log("Failed to create address from provided public key. Error: \(error)")
            stateSubject.send(.failedToInitialize(.failedToGenerateAddress))
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
            let currencyId = tokenItem?.currencyId
        else {
            return nil
        }

        let converter = BalanceConverter()
        return converter.convertToFiat(balanceValue, currencyId: currencyId)
    }
}

extension VisaWalletModel: MainHeaderBalanceProvider {
    var balanceProvider: AnyPublisher<LoadingValue<AttributedString>, Never> {
        stateSubject.combineLatest(balancesSubject)
            .map { [weak self] state, balances -> LoadingValue<AttributedString> in
                guard let self else {
                    return .loading
                }

                switch state {
                case .notInitialized, .loading:
                    return .loading
                case .failedToInitialize(let error):
                    return .failedToLoad(error: error)
                case .idle:
                    if let balances, let tokenItem {
                        let balanceFormatter = BalanceFormatter()
                        let formattedBalance = balanceFormatter.formatCryptoBalance(balances.available, currencyCode: tokenItem.currencySymbol)
                        let formattedForMain = balanceFormatter.formatAttributedTotalBalance(fiatBalance: formattedBalance)
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
        case missingPublicKey
        case failedToGenerateAddress

        var notificationEvent: VisaNotificationEvent {
            switch self {
            case .missingRequiredBlockchain: return .missingRequiredBlockchain
            case .invalidBlockchain: return .notValidBlockchain
            case .noPaymentAccount: return .failedToLoadPaymentAccount
            case .missingPublicKey: return .missingPublicKey
            case .failedToGenerateAddress: return .failedToGenerateAddress
            }
        }
    }
}
