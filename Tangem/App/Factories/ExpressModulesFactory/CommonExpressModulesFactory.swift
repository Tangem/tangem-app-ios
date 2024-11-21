//
//  DependenciesFactory.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import BlockchainSdk

class CommonExpressModulesFactory {
    @Injected(\.expressPendingTransactionsRepository) private var pendingTransactionRepository: ExpressPendingTransactionRepository

    private let userWalletModel: UserWalletModel
    private let initialWalletModel: WalletModel
    private let expressAPIProviderFactory = ExpressAPIProviderFactory()

    // MARK: - Internal

    private lazy var expressInteractor = makeExpressInteractor()
    private lazy var expressAPIProvider = makeExpressAPIProvider()
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
            feeFormatter: feeFormatter,
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

    func makeExpressFeeSelectorViewModel(coordinator: ExpressFeeSelectorRoutable) -> ExpressFeeSelectorViewModel {
        ExpressFeeSelectorViewModel(
            feeFormatter: feeFormatter,
            expressInteractor: expressInteractor,
            coordinator: coordinator
        )
    }

    func makeExpressApproveViewModel(
        providerName: String,
        selectedPolicy: ExpressApprovePolicy,
        coordinator: ExpressApproveRoutable
    ) -> ExpressApproveViewModel {
        let tokenItem = expressInteractor.getSender().tokenItem

        return ExpressApproveViewModel(
            settings: .init(
                subtitle: Localization.givePermissionSwapSubtitle(providerName, tokenItem.currencySymbol),
                feeFooterText: Localization.swapGivePermissionFeeFooter,
                tokenItem: tokenItem,
                feeTokenItem: expressInteractor.getSender().feeTokenItem,
                selectedPolicy: selectedPolicy
            ),
            feeFormatter: feeFormatter,
            logger: logger,
            approveViewModelInput: expressInteractor,
            coordinator: coordinator
        )
    }

    func makeExpressProvidersSelectorViewModel(
        coordinator: ExpressProvidersSelectorRoutable
    ) -> ExpressProvidersSelectorViewModel {
        ExpressProvidersSelectorViewModel(
            priceChangeFormatter: priceChangeFormatter,
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
            feeFormatter: feeFormatter,
            coordinator: coordinator
        )
    }

    func makePendingExpressTransactionsManager() -> any PendingExpressTransactionsManager {
        let tokenFinder = CommonTokenFinder(supportedBlockchains: userWalletModel.config.supportedBlockchains)

        let expressRefundedTokenHandler = CommonExpressRefundedTokenHandler(
            userTokensManager: userWalletModel.userTokensManager,
            tokenFinder: tokenFinder
        )

        let pendingExpressTransactionsManager = CommonPendingExpressTransactionsManager(
            userWalletId: userWalletModel.userWalletId.stringValue,
            walletModel: initialWalletModel,
            expressRefundedTokenHandler: expressRefundedTokenHandler
        )

        return pendingExpressTransactionsManager
    }

    func makePendingOnrampTransactionsManager() -> any PendingOnrampTransactionsManager {
        CommonPendingOnrampTransactionsManager(
            userWalletId: userWalletModel.userWalletId.stringValue,
            walletModel: initialWalletModel
        )
    }
}

// MARK: Dependencies

private extension CommonExpressModulesFactory {
    var feeFormatter: FeeFormatter {
        CommonFeeFormatter(
            balanceFormatter: balanceFormatter,
            balanceConverter: balanceConverter
        )
    }

    var expressProviderFormatter: ExpressProviderFormatter {
        ExpressProviderFormatter(balanceFormatter: balanceFormatter)
    }

    var notificationManager: NotificationManager {
        ExpressNotificationManager(expressInteractor: expressInteractor)
    }

    var priceChangeFormatter: PriceChangeFormatter { .init() }
    var balanceConverter: BalanceConverter { .init() }
    var balanceFormatter: BalanceFormatter { .init() }
    var providerFormatter: ExpressProviderFormatter { .init(balanceFormatter: balanceFormatter) }
    var walletModelsManager: WalletModelsManager { userWalletModel.walletModelsManager }
    var userWalletId: String { userWalletModel.userWalletId.stringValue }
    var signer: TangemSigner { userWalletModel.signer }
    var logger: Logger { AppLog.shared }
    var analyticsLogger: ExpressAnalyticsLogger { CommonExpressAnalyticsLogger() }

    var expressTokensListAdapter: ExpressTokensListAdapter {
        CommonExpressTokensListAdapter(userWalletModel: userWalletModel)
    }

    var expressDestinationService: ExpressDestinationService {
        CommonExpressDestinationService(
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
        let expressManager = TangemExpressFactory().makeExpressManager(
            expressAPIProvider: expressAPIProvider,
            allowanceProvider: allowanceProvider,
            feeProvider: expressFeeProvider,
            expressRepository: expressRepository,
            logger: logger,
            analyticsLogger: analyticsLogger
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
            expressAPIProvider: expressAPIProvider,
            signer: signer,
            logger: logger
        )

        return interactor
    }

    func makeAllowanceProvider() -> UpdatableAllowanceProvider {
        CommonAllowanceProvider(walletModel: initialWalletModel)
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
