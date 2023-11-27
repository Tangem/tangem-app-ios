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
    private let walletModel: WalletModel
    private let signer: TransactionSigner
    private let ethereumNetworkProvider: EthereumNetworkProvider
    private let ethereumTransactionProcessor: EthereumTransactionProcessor
    private let logger: SwappingLogger
    private let referrer: SwappingReferrerAccount?
    private let source: Currency
    private let walletModelTokens: [Token]
    private let destination: Currency?

    // MARK: - Internal

    private var _swappingInteractor: SwappingInteractor?

    init(inputModel: InputModel) {
        userTokensManager = inputModel.userTokensManager
        walletModel = inputModel.walletModel
        signer = inputModel.signer
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
            blockchain: walletModel.wallet.blockchain,
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
            fiatRatesProvider: fiatRatesProvider,
            swappingInteractor: swappingInteractor,
            swappingFeeFormatter: swappingFeeFormatter,
            pendingTransactionRepository: nil,
            logger: logger,
            expressInteractor: nil,
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
        SwappingDestinationService(
            blockchain: walletModel.blockchainNetwork.blockchain,
            mapper: currencyMapper,
            walletModelTokens: walletModelTokens
        )
    }

    var currencyMapper: CurrencyMapping { CurrencyMapper() }

    var tokenIconURLBuilder: TokenIconURLBuilding { TokenIconURLBuilder() }

    var userCurrenciesProvider: UserCurrenciesProviding {
        UserCurrenciesProvider(
            blockchain: walletModel.blockchainNetwork.blockchain,
            walletModelTokens: walletModelTokens,
            currencyMapper: currencyMapper
        )
    }

    var transactionSender: SwappingTransactionSender {
        CommonSwappingTransactionSender(
            walletModel: walletModel,
            transactionSigner: signer,
            ethereumNetworkProvider: ethereumNetworkProvider,
            currencyMapper: currencyMapper
        )
    }

    var fiatRatesProvider: FiatRatesProviding {
        SwappingRatesProvider()
    }

    var swappingFeeFormatter: SwappingFeeFormatter {
        CommonSwappingFeeFormatter(
            balanceFormatter: .init(), balanceConverter: .init(),
            fiatRatesProvider: fiatRatesProvider
        )
    }

    var explorerURLService: ExplorerURLService {
        CommonExplorerURLService()
    }

    var walletDataProvider: SwappingWalletDataProvider {
        CommonSwappingWalletDataProvider(
            wallet: walletModel.wallet,
            ethereumNetworkProvider: ethereumNetworkProvider,
            ethereumTransactionProcessor: ethereumTransactionProcessor,
            currencyMapper: currencyMapper
        )
    }

    var swappingInteractor: SwappingInteractor {
        if let interactor = _swappingInteractor {
            return interactor
        }

        let swappingManager = TangemSwappingFactory().makeSwappingManager(
            walletDataProvider: walletDataProvider,
            referrer: referrer,
            source: source,
            destination: destination,
            logger: logger
        )

        let interactor = SwappingInteractor(
            swappingManager: swappingManager,
            userTokensManager: userTokensManager,
            currencyMapper: currencyMapper,
            blockchainNetwork: walletModel.blockchainNetwork
        )

        _swappingInteractor = interactor
        return interactor
    }
}

extension CommonSwappingModulesFactory {
    struct InputModel {
        let userTokensManager: UserTokensManager
        let walletModel: WalletModel
        let signer: TransactionSigner
        let ethereumNetworkProvider: EthereumNetworkProvider
        let ethereumTransactionProcessor: EthereumTransactionProcessor
        let logger: SwappingLogger
        let referrer: SwappingReferrerAccount?
        let source: Currency
        let walletModelTokens: [Token]
        let destination: Currency?

        init(
            userTokensManager: UserTokensManager,
            walletModel: WalletModel,
            signer: TransactionSigner,
            ethereumNetworkProvider: EthereumNetworkProvider,
            ethereumTransactionProcessor: EthereumTransactionProcessor,
            logger: SwappingLogger,
            referrer: SwappingReferrerAccount?,
            source: Currency,
            walletModelTokens: [Token],
            destination: Currency? = nil
        ) {
            self.userTokensManager = userTokensManager
            self.walletModel = walletModel
            self.signer = signer
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
