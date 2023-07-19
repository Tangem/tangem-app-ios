//
//  SwappingInteractor.swift
//  Tangem
//
//  Created by Sergey Balashov on 04.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSwapping

class SwappingInteractor {
    // MARK: - Public

    public let state = CurrentValueSubject<SwappingAvailabilityState, Never>(.idle)

    // MARK: - Dependencies

    private let swappingManager: SwappingManager
    private let userTokensManager: UserTokensManager
    private let currencyMapper: CurrencyMapping
    private let blockchainNetwork: BlockchainNetwork

    // MARK: - Private

    private var updateStateTask: Task<Void, Error>?

    init(
        swappingManager: SwappingManager,
        userTokensManager: UserTokensManager,
        currencyMapper: CurrencyMapping,
        blockchainNetwork: BlockchainNetwork
    ) {
        self.swappingManager = swappingManager
        self.userTokensManager = userTokensManager
        self.currencyMapper = currencyMapper
        self.blockchainNetwork = blockchainNetwork
    }
}

// MARK: - Public

extension SwappingInteractor {
    func getAvailabilityState() -> SwappingAvailabilityState {
        state.value
    }

    func getSwappingItems() -> SwappingItems {
        swappingManager.getSwappingItems()
    }

    func getReferrerAccountFee() -> Decimal? {
        swappingManager.getReferrerAccount()?.fee
    }

    func getSwappingApprovePolicy() -> SwappingApprovePolicy {
        swappingManager.getSwappingApprovePolicy()
    }

    func getSwappingGasPricePolicy() -> SwappingGasPricePolicy {
        swappingManager.getSwappingGasPricePolicy()
    }

    func update(swappingItems: SwappingItems) async -> SwappingItems {
        AppLog.shared.debug("[Swap] SwappingInteractor will update swappingItems to \(swappingItems)")
        updateState(.idle)
        swappingManager.update(swappingItems: swappingItems)
        return await swappingManager.refreshBalances()
    }

    func update(amount: Decimal?) {
        AppLog.shared.debug("[Swap] SwappingInteractor will update amount to \(amount as Any)")
        swappingManager.update(amount: amount)
        refresh(type: .full)
    }

    func update(approvePolicy: SwappingApprovePolicy) {
        guard swappingManager.getSwappingItems().source.isToken else {
            assertionFailure("Don't call this method if source currency isn't a token")
            return
        }

        swappingManager.update(approvePolicy: approvePolicy)
        refresh(type: .full)
    }

    func update(gasPricePolicy: SwappingGasPricePolicy) {
        swappingManager.update(gasPricePolicy: gasPricePolicy)
        updateState(with: gasPricePolicy)
    }

    func refresh(type: SwappingManagerRefreshType) {
        AppLog.shared.debug("[Swap] SwappingInteractor received the request for refresh with \(type)")

        guard let amount = swappingManager.getAmount(), amount > 0 else {
            updateState(.idle)
            return
        }

        AppLog.shared.debug("[Swap] SwappingInteractor start refreshing task")
        updateState(.loading(type))
        updateStateTask = runTask(in: self) { root in
            await root.updateState(root.swappingManager.refresh(type: type))
        }
    }

    func cancelRefresh() {
        guard updateStateTask != nil else {
            return
        }

        AppLog.shared.debug("[Swap] SwappingInteractor cancel the refreshing task")

        updateStateTask?.cancel()
        updateStateTask = nil
    }

    func didSendApproveTransaction(swappingTxData: SwappingTransactionData) {
        swappingManager.didSendApproveTransaction(swappingTxData: swappingTxData)
        refresh(type: .full)

        let permissionType: Analytics.ParameterValue = {
            switch getSwappingApprovePolicy() {
            case .amount: return .oneTransactionApprove
            case .unlimited: return .unlimitedApprove
            }
        }()

        Analytics.log(event: .transactionSent, params: [
            .commonSource: Analytics.ParameterValue.transactionSourceApprove.rawValue,
            .feeType: getAnalyticsFeeType().rawValue,
            .token: swappingTxData.sourceCurrency.symbol,
            .blockchain: swappingTxData.sourceBlockchain.name,
            .permissionType: permissionType.rawValue,
        ])
    }

    func didSendSwapTransaction(swappingTxData: SwappingTransactionData) {
        updateState(.idle)
        addDestinationTokenToUserWalletList()

        Analytics.log(event: .transactionSent, params: [
            .commonSource: Analytics.ParameterValue.transactionSourceSwap.rawValue,
            .token: swappingTxData.sourceCurrency.symbol,
            .blockchain: swappingTxData.sourceBlockchain.name,
            .feeType: getAnalyticsFeeType().rawValue,
        ])
    }
}

// MARK: - Private

private extension SwappingInteractor {
    func updateState(_ state: SwappingAvailabilityState) {
        AppLog.shared.debug("[Swap] SwappingInteractor update state to \(state)")

        self.state.send(state)
    }

    func updateState(with gasPricePolicy: SwappingGasPricePolicy) {
        guard case .available(let model) = getAvailabilityState(),
              let gas = model.gasOptions.first(where: { $0.policy == gasPricePolicy }) else {
            return
        }

        let transactionData = model.transactionData
        let newData = SwappingTransactionData(
            sourceCurrency: transactionData.sourceCurrency,
            sourceBlockchain: transactionData.sourceBlockchain,
            destinationCurrency: transactionData.destinationCurrency,
            sourceAddress: transactionData.sourceAddress,
            destinationAddress: transactionData.destinationAddress,
            txData: transactionData.txData,
            sourceAmount: transactionData.sourceAmount,
            destinationAmount: transactionData.destinationAmount,
            value: transactionData.value,
            gas: gas
        )

        let availabilityModel = SwappingAvailabilityModel(
            transactionData: newData,
            gasOptions: model.gasOptions,
            restrictions: model.restrictions
        )

        updateState(.available(availabilityModel))
    }

    func addDestinationTokenToUserWalletList() {
        guard let destination = getSwappingItems().destination,
              let token = currencyMapper.mapToToken(currency: destination) else {
            return
        }

        userTokensManager.add(.token(token, blockchainNetwork.blockchain), derivationPath: blockchainNetwork.derivationPath, completion: { _ in })
    }

    func getAnalyticsFeeType() -> Analytics.ParameterValue {
        switch swappingManager.getSwappingGasPricePolicy() {
        case .normal: return .transactionFeeNormal
        case .priority: return .transactionFeeMax
        }
    }
}
