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

class CommonExpressModulesFactory {
    @Injected(\.keysManager) private var keysManager: KeysManager
    @Injected(\.expressPendingTransactionsRepository) private var pendingTransactionRepository: ExpressPendingTransactionRepository

    private let userWalletModel: UserWalletModel
    private let initialWalletModel: WalletModel
    private let expressAPIProviderFactory = ExpressAPIProviderFactory()

    // MARK: - Internal

    private lazy var expressInteractor = makeExpressInteractor()
    private lazy var expressAPIProvider = makeExpressAPIProvider()
    private lazy var swappingFactory = TangemSwappingFactory(oneInchApiKey: "")
    private lazy var allowanceProvider = makeAllowanceProvider()
    private lazy var expressFeeProvider = makeExpressFeeProvider()
    private lazy var expressRepository = makeExpressRepository()

    init(inputModel: InputModel) {
        userWalletModel = inputModel.userWalletModel
        initialWalletModel = inputModel.initialWalletModel
    }
}

// MARK: - ExpressModulesFactory

extension CommonExpressModulesFactory: ExpressModulesFactory {
    func makeExpressViewModel(coordinator: ExpressRoutable) -> ExpressViewModel {
        let notificationManager = notificationManager
        let model = ExpressViewModel(
            initialWallet: initialWalletModel,
            userWalletModel: userWalletModel,
            swappingFeeFormatter: swappingFeeFormatter,
            balanceConverter: balanceConverter,
            balanceFormatter: balanceFormatter,
            expressProviderFormatter: expressProviderFormatter,
            notificationManager: notificationManager,
            expressRepository: expressRepository,
            interactor: expressInteractor,
            coordinator: coordinator
        )
        notificationManager.setupManager(with: model)
        return model
    }

    func makeExpressTokensListViewModel(
        swapDirection: ExpressTokensListViewModel.SwapDirection,
        coordinator: ExpressTokensListRoutable
    ) -> ExpressTokensListViewModel {
        ExpressTokensListViewModel(
            swapDirection: swapDirection,
            expressTokensListAdapter: expressTokensListAdapter,
            expressRepository: expressRepository,
            expressInteractor: expressInteractor,
            coordinator: coordinator
        )
    }

    func makeExpressFeeSelectorViewModel(coordinator: ExpressFeeBottomSheetRoutable) -> ExpressFeeBottomSheetViewModel {
        ExpressFeeBottomSheetViewModel(
            swappingFeeFormatter: swappingFeeFormatter,
            expressInteractor: expressInteractor,
            coordinator: coordinator
        )
    }

    func makeSwappingApproveViewModel(coordinator: SwappingApproveRoutable) -> SwappingApproveViewModel {
        SwappingApproveViewModel(
            swappingFeeFormatter: swappingFeeFormatter,
            pendingTransactionRepository: pendingTransactionRepository,
            logger: logger,
            expressInteractor: expressInteractor,
            coordinator: coordinator
        )
    }

    func makeExpressProvidersSelectorViewModel(
        coordinator: ExpressProvidersSelectorRoutable
    ) -> ExpressProvidersSelectorViewModel {
        ExpressProvidersSelectorViewModel(
            percentFormatter: percentFormatter,
            expressProviderFormatter: expressProviderFormatter,
            expressRepository: expressRepository,
            expressInteractor: expressInteractor,
            coordinator: coordinator
        )
    }

    func makeExpressSuccessSentViewModel(data: SentExpressTransactionData, coordinator: ExpressSuccessSentRoutable) -> ExpressSuccessSentViewModel {
        ExpressSuccessSentViewModel(
            data: data,
            initialWallet: initialWalletModel,
            balanceConverter: balanceConverter,
            balanceFormatter: balanceFormatter,
            providerFormatter: providerFormatter,
            feeFormatter: swappingFeeFormatter,
            coordinator: coordinator
        )
    }
}

// MARK: Dependencies

private extension CommonExpressModulesFactory {
    var swappingFeeFormatter: SwappingFeeFormatter {
        CommonSwappingFeeFormatter(
            balanceFormatter: balanceFormatter,
            balanceConverter: balanceConverter,
            fiatRatesProvider: SwappingRatesProvider()
        )
    }

    var expressProviderFormatter: ExpressProviderFormatter {
        ExpressProviderFormatter(balanceFormatter: balanceFormatter)
    }

    var notificationManager: NotificationManager {
        ExpressNotificationManager(expressInteractor: expressInteractor)
    }

    var explorerURLService: ExplorerURLService {
        CommonExplorerURLService()
    }

    var percentFormatter: PercentFormatter { .init() }
    var balanceConverter: BalanceConverter { .init() }
    var balanceFormatter: BalanceFormatter { .init() }
    var providerFormatter: ExpressProviderFormatter { .init(balanceFormatter: balanceFormatter) }
    var walletModelsManager: WalletModelsManager { userWalletModel.walletModelsManager }
    var userWalletId: String { userWalletModel.userWalletId.stringValue }
    var signer: TransactionSigner { userWalletModel.signer }
    var logger: SwappingLogger { AppLog.shared }
    var userTokensManager: UserTokensManager { userWalletModel.userTokensManager }

    var expressTokensListAdapter: ExpressTokensListAdapter {
        CommonExpressTokensListAdapter(userWalletModel: userWalletModel)
    }

    var expressDestinationService: ExpressDestinationService {
        CommonExpressDestinationService(
            pendingTransactionRepository: pendingTransactionRepository,
            walletModelsManager: walletModelsManager,
            expressRepository: expressRepository
        )
    }

    var expressTransactionBuilder: ExpressTransactionBuilder {
        CommonExpressTransactionBuilder()
    }

    // MARK: - Methods

    func makeExpressAPIProvider() -> ExpressAPIProvider {
        expressAPIProviderFactory.makeExpressAPIProvider(userId: userWalletId, logger: logger)
    }

    func makeExpressInteractor() -> ExpressInteractor {
        let expressManager = swappingFactory.makeExpressManager(
            expressAPIProvider: expressAPIProvider,
            allowanceProvider: allowanceProvider,
            feeProvider: expressFeeProvider,
            expressRepository: expressRepository,
            logger: logger
        )

        let interactor = ExpressInteractor(
            userWalletId: userWalletId,
            initialWallet: initialWalletModel,
            expressManager: expressManager,
            allowanceProvider: allowanceProvider,
            feeProvider: expressFeeProvider,
            expressRepository: expressRepository,
            expressPendingTransactionRepository: pendingTransactionRepository,
            expressDestinationService: expressDestinationService,
            expressTransactionBuilder: expressTransactionBuilder,
            signer: signer,
            logger: logger
        )

        return interactor
    }

    func makeAllowanceProvider() -> ExpressAllowanceProvider {
        let provider = CommonExpressAllowanceProvider(logger: logger)
        provider.setup(wallet: initialWalletModel)
        return provider
    }

    func makeExpressFeeProvider() -> ExpressFeeProvider {
        return CommonExpressFeeProvider(wallet: initialWalletModel)
    }

    func makeExpressRepository() -> ExpressRepository {
        CommonExpressRepository(
            walletModelsManager: walletModelsManager,
            expressAPIProvider: expressAPIProvider
        )
    }
}

extension CommonExpressModulesFactory {
    struct InputModel {
        let userWalletModel: UserWalletModel
        let initialWalletModel: WalletModel
    }
}
