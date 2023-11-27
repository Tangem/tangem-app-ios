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

    private let userWalletModel: UserWalletModel
    private let initialWalletModel: WalletModel

    // MARK: - Internal

    private lazy var expressInteractor = makeExpressInteractor()
    private lazy var expressAPICredential = makeExpressAPICredential()
    private lazy var expressAPIProvider = makeExpressAPIProvider()
    private lazy var swappingFactory = TangemSwappingFactory()
    private lazy var allowanceProvider = makeAllowanceProvider()

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
            expressAPIProvider: expressAPIProvider,
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
            transactionSender: nil,
            fiatRatesProvider: nil,
            swappingInteractor: nil,
            swappingFeeFormatter: swappingFeeFormatter,
            pendingTransactionRepository: pendingTransactionRepository,
            logger: logger,
            expressInteractor: expressInteractor,
            coordinator: coordinator
        )
    }

    func makeExpressProvidersBottomSheetViewModel(
        coordinator: ExpressProvidersBottomSheetRoutable
    ) -> ExpressProvidersBottomSheetViewModel {
        ExpressProvidersBottomSheetViewModel(
            percentFormatter: percentFormatter,
            expressProviderFormatter: expressProviderFormatter,
            expressInteractor: expressInteractor,
            coordinator: coordinator
        )
    }

    func makeExpressSuccessSentViewModel(data: SentExpressTransactionData, coordinator: ExpressSuccessSentRoutable) -> ExpressSuccessSentViewModel {
        ExpressSuccessSentViewModel(
            data: data,
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

    var notificationManager: ExpressNotificationManager {
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

    var pendingTransactionRepository: ExpressPendingTransactionRepository {
        CommonExpressPendingTransactionRepository()
    }

    var expressDestinationService: ExpressDestinationService {
        CommonExpressDestinationService(
            pendingTransactionRepository: pendingTransactionRepository,
            walletModelsManager: walletModelsManager
        )
    }

    var expressTransactionBuilder: ExpressTransactionBuilder {
        CommonExpressTransactionBuilder()
    }

    // MARK: - Methods

    func makeExpressInteractor() -> ExpressInteractor {
        let expressManager = swappingFactory.makeExpressManager(
            expressAPIProvider: expressAPIProvider,
            allowanceProvider: allowanceProvider,
            logger: logger
        )

        let interactor = ExpressInteractor(
            sender: initialWalletModel,
            expressManager: expressManager,
            allowanceProvider: allowanceProvider,
            expressPendingTransactionRepository: pendingTransactionRepository,
            expressDestinationService: expressDestinationService,
            expressTransactionBuilder: expressTransactionBuilder,
            signer: signer,
            logger: logger
        )

        return interactor
    }

    func makeAllowanceProvider() -> ExpressAllowanceProvider {
        let provider = CommonExpressAllowanceProvider()
        provider.setup(wallet: initialWalletModel)
        return provider
    }

    func makeExpressAPIProvider() -> ExpressAPIProvider {
        swappingFactory.makeExpressAPIProvider(
            credential: expressAPICredential,
            configuration: .defaultConfiguration,
            logger: logger
        )
    }

    func makeExpressAPICredential() -> ExpressAPICredential {
        ExpressAPICredential(
            apiKey: keysManager.tangemExpressApiKey,
            userId: userWalletId,
            sessionId: UUID().uuidString
        )
    }
}

extension CommonExpressModulesFactory {
    struct InputModel {
        let userWalletModel: UserWalletModel
        let initialWalletModel: WalletModel
    }
}
