//
//  DependenciesFactory.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping
import BlockchainSdk

class CommonSwappingModulesFactory {
    private let userTokensManager: UserTokensManager
    private let blockchainNetwork: BlockchainNetwork
    private let wallet: Wallet
    private let sender: TransactionSender
    private let signer: TransactionSigner
    private let transactionCreator: TransactionCreator
    private let ethereumNetworkProvider: EthereumNetworkProvider
    private let ethereumTransactionProcessor: EthereumTransactionProcessor
    private let logger: SwappingLogger
    private let referrer: SwappingReferrerAccount?
    private let source: Currency
    private let walletModelTokens: [Token]
    private let destination: Currency?

    private lazy var swappingInteractor = makeSwappingInteractor(source: source, destination: destination)

    init(inputModel: InputModel) {
        userTokensManager = inputModel.userTokensManager
        wallet = inputModel.wallet
        blockchainNetwork = inputModel.blockchainNetwork
        sender = inputModel.sender
        signer = inputModel.signer
        transactionCreator = inputModel.transactionCreator
        ethereumNetworkProvider = inputModel.ethereumNetworkProvider
        ethereumTransactionProcessor = inputModel.ethereumTransactionProcessor
        logger = inputModel.logger
        referrer = inputModel.referrer
        source = inputModel.source
        walletModelTokens = inputModel.walletModelTokens
        destination = inputModel.destination
    }
}

// MARK: - SwappingModulesFactory

extension CommonSwappingModulesFactory: SwappingModulesFactory {
    func makeSwappingViewModel(coordinator: SwappingRoutable) -> SwappingViewModel {
        SwappingViewModel(
            initialSourceCurrency: source,
            swappingInteractor: swappingInteractor,
            swappingDestinationService: swappingDestinationService,
            tokenIconURLBuilder: tokenIconURLBuilder,
            transactionSender: transactionSender,
            fiatRatesProvider: fiatRatesProvider,
            swappingFeeFormatter: swappingFeeFormatter,
            coordinator: coordinator
        )
    }

    func makeSwappingTokenListViewModel(coordinator: SwappingTokenListRoutable) -> SwappingTokenListViewModel {
        SwappingTokenListViewModel(
            sourceCurrency: source,
            userCurrenciesProvider: userCurrenciesProvider,
            tokenIconURLBuilder: tokenIconURLBuilder,
            currencyMapper: currencyMapper,
            walletDataProvider: walletDataProvider,
            fiatRatesProvider: fiatRatesProvider,
            coordinator: coordinator
        )
    }

    func makeSwappingApproveViewModel(coordinator: SwappingApproveRoutable) -> SwappingApproveViewModel {
        SwappingApproveViewModel(
            transactionSender: transactionSender,
            swappingInteractor: swappingInteractor,
            fiatRatesProvider: fiatRatesProvider,
            coordinator: coordinator
        )
    }

    func makeSwappingSuccessViewModel(
        inputModel: SwappingSuccessInputModel,
        coordinator: SwappingSuccessRoutable
    ) -> SwappingSuccessViewModel {
        SwappingSuccessViewModel(
            inputModel: inputModel,
            explorerURLService: explorerURLService,
            coordinator: coordinator
        )
    }
}

// MARK: Dependencies

private extension CommonSwappingModulesFactory {
    var swappingDestinationService: SwappingDestinationServicing {
        SwappingDestinationService(blockchain: blockchainNetwork.blockchain, mapper: currencyMapper, walletModelTokens: walletModelTokens)
    }

    var currencyMapper: CurrencyMapping { CurrencyMapper() }

    var tokenIconURLBuilder: TokenIconURLBuilding { TokenIconURLBuilder(baseURL: CoinsResponse.baseURL) }

    var userCurrenciesProvider: UserCurrenciesProviding {
        UserCurrenciesProvider(
            blockchain: blockchainNetwork.blockchain,
            walletModelTokens: walletModelTokens,
            currencyMapper: currencyMapper
        )
    }

    var transactionSender: SwappingTransactionSender {
        CommonSwappingTransactionSender(
            transactionCreator: transactionCreator,
            transactionSender: sender,
            transactionSigner: signer,
            ethereumNetworkProvider: ethereumNetworkProvider,
            currencyMapper: currencyMapper
        )
    }

    var fiatRatesProvider: FiatRatesProviding {
        SwappingRatesProvider()
    }

    var swappingFeeFormatter: SwappingFeeFormatter {
        CommonSwappingFeeFormatter(fiatRatesProvider: fiatRatesProvider)
    }

    var explorerURLService: ExplorerURLService {
        CommonExplorerURLService()
    }

    var walletDataProvider: SwappingWalletDataProvider {
        CommonSwappingWalletDataProvider(
            wallet: wallet,
            ethereumNetworkProvider: ethereumNetworkProvider,
            ethereumTransactionProcessor: ethereumTransactionProcessor,
            currencyMapper: currencyMapper
        )
    }

    func makeSwappingInteractor(source: Currency, destination: Currency?) -> SwappingInteractor {
        let swappingManager = makeSwappingManager(source: source, destination: destination)
        return SwappingInteractor(
            swappingManager: swappingManager,
            userTokensManager: userTokensManager,
            currencyMapper: currencyMapper,
            blockchainNetwork: blockchainNetwork
        )
    }

    func makeSwappingManager(source: Currency, destination: Currency?) -> SwappingManager {
        TangemSwappingFactory().makeSwappingManager(
            walletDataProvider: walletDataProvider,
            referrer: referrer,
            source: source,
            destination: destination,
            logger: logger
        )
    }
}

extension CommonSwappingModulesFactory {
    struct InputModel {
        let userTokensManager: UserTokensManager
        let wallet: Wallet
        let blockchainNetwork: BlockchainNetwork
        let sender: TransactionSender
        let signer: TransactionSigner
        let transactionCreator: TransactionCreator
        let ethereumNetworkProvider: EthereumNetworkProvider
        let ethereumTransactionProcessor: EthereumTransactionProcessor
        let logger: SwappingLogger
        let referrer: SwappingReferrerAccount?
        let source: Currency
        let walletModelTokens: [Token]
        let destination: Currency?

        init(
            userTokensManager: UserTokensManager,
            wallet: Wallet,
            blockchainNetwork: BlockchainNetwork,
            sender: TransactionSender,
            signer: TransactionSigner,
            transactionCreator: TransactionCreator,
            ethereumNetworkProvider: EthereumNetworkProvider,
            ethereumTransactionProcessor: EthereumTransactionProcessor,
            logger: SwappingLogger,
            referrer: SwappingReferrerAccount?,
            source: Currency,
            walletModelTokens: [Token],
            destination: Currency? = nil
        ) {
            self.userTokensManager = userTokensManager
            self.wallet = wallet
            self.blockchainNetwork = blockchainNetwork
            self.sender = sender
            self.signer = signer
            self.transactionCreator = transactionCreator
            self.ethereumNetworkProvider = ethereumNetworkProvider
            self.ethereumTransactionProcessor = ethereumTransactionProcessor
            self.logger = logger
            self.referrer = referrer
            self.source = source
            self.walletModelTokens = walletModelTokens
            self.destination = destination
        }
    }
}
