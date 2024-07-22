//
//  MarketsTokenDetailsPortfolioCoordinatorFactory.swift
//  Tangem
//
//  Created by skibinalexander on 14.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsTokenDetailsPortfolioCoordinatorFactory {
    // MARK: - Services

    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    var canBuy: Bool {
        return tangemApiService.geoIpRegionCode != LanguageCode.ru
    }

    // MARK: - Utils

    private func buildExchangeCryptoUtility(for walletModel: WalletModel) -> ExchangeCryptoUtility {
        return ExchangeCryptoUtility(
            blockchain: walletModel.blockchainNetwork.blockchain,
            address: walletModel.defaultAddress,
            amountType: walletModel.amountType
        )
    }

    // MARK: - Make

    func makeSendCoordinator(
        for walletModel: WalletModel,
        with userWalletModel: UserWalletModel,
        dismissAction: @escaping Action<(walletModel: WalletModel, userWalletModel: UserWalletModel)?>
    ) -> SendCoordinator {
        let coordinator = SendCoordinator(dismissAction: dismissAction)
        let options = SendCoordinator.Options(
            walletModel: walletModel,
            userWalletModel: userWalletModel,
            type: .send
        )
        coordinator.start(with: options)
        return coordinator
    }

    func makeExpressCoordinator(
        for walletModel: WalletModel,
        with userWalletModel: UserWalletModel,
        dismissAction: @escaping Action<(walletModel: WalletModel, userWalletModel: UserWalletModel)?>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) -> ExpressCoordinator {
        let input = CommonExpressModulesFactory.InputModel(userWalletModel: userWalletModel, initialWalletModel: walletModel)
        let factory = CommonExpressModulesFactory(inputModel: input)
        let coordinator = ExpressCoordinator(
            factory: factory,
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )

        coordinator.start(with: .default)

        return coordinator
    }

    func makeStakingDetailsCoordinator(
        for walletModel: WalletModel,
        with userWalletModel: UserWalletModel,
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) -> StakingDetailsCoordinator? {
        guard let stakingManager = walletModel.stakingManager else {
            return nil
        }

        let coordinator = StakingDetailsCoordinator(
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )

        let options = StakingDetailsCoordinator.InputOptions(
            userWalletModel: userWalletModel,
            walletModel: walletModel,
            manager: stakingManager
        )

        coordinator.start(with: options)

        return coordinator
    }

    func makeBuyURL(
        for walletModel: WalletModel,
        with userWalletModel: UserWalletModel
    ) -> URL? {
        let blockchain = walletModel.blockchainNetwork.blockchain
        let exchangeUtility = buildExchangeCryptoUtility(for: walletModel)

        if let token = walletModel.amountType.token, blockchain == .ethereum(testnet: true) {
            TestnetBuyCryptoService().buyCrypto(
                .erc20Token(token, walletModel: walletModel, signer: userWalletModel.signer)
            )

            return nil
        }

        return exchangeUtility.buyURL
    }

    func makeSellCryptoRequest(from closeURL: URL, with walletModel: WalletModel) -> SellCryptoRequest? {
        let exchangeUtility = buildExchangeCryptoUtility(for: walletModel)
        return exchangeUtility.extractSellCryptoRequest(from: closeURL.absoluteString)
    }

    func makeSell(
        request: SellCryptoRequest,
        for walletModel: WalletModel,
        with userWalletModel: UserWalletModel,
        dismissAction: @escaping Action<(walletModel: WalletModel, userWalletModel: UserWalletModel)?>
    ) -> SendCoordinator? {
        let coordinator = SendCoordinator(dismissAction: dismissAction)

        let options = SendCoordinator.Options(
            walletModel: walletModel,
            userWalletModel: userWalletModel,
            type: .sell(parameters: .init(amount: request.amount, destination: request.targetAddress, tag: request.tag))
        )
        coordinator.start(with: options)
        return coordinator
    }

    func makeSellURL(for walletModel: WalletModel) -> URL? {
        let exchangeUtility = buildExchangeCryptoUtility(for: walletModel)
        return exchangeUtility.sellURL
    }
}
