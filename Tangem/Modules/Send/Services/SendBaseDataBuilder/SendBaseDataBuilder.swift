//
//  SendBaseDataBuilder.swift
//  TangemApp
//
//  Created by Sergey Balashov on 20.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemStaking
import TangemExpress

protocol SendBaseDataBuilder: SendGenericBaseDataBuilder {
    func makeMailData(transaction: BSDKTransaction, error: SendTxError) -> (dataCollector: EmailDataCollector, recipient: String)
}

protocol StakingBaseDataBuilder: SendGenericBaseDataBuilder {
    func makeMailData(stakingRequestError error: Error) throws -> (dataCollector: EmailDataCollector, recipient: String)
    func makeMailData(action: StakingTransactionAction, error: SendTxError) -> (dataCollector: EmailDataCollector, recipient: String)
    func makeDataForExpressApproveViewModel() throws -> (settings: ExpressApproveViewModel.Settings, approveViewModelInput: any ApproveViewModelInput)
}

protocol OnrampBaseDataBuilder: SendGenericBaseDataBuilder {
    func makeDataForOnrampCountryBottomSheet() -> OnrampRepository
    func makeDataForOnrampCountrySelectorView() -> (preferenceRepository: OnrampRepository, dataRepository: OnrampDataRepository)
    func makeDataForOnrampProvidersPaymentMethodsView() -> (providersBuilder: OnrampProvidersBuilder, paymentMethodsBuilder: OnrampPaymentMethodsBuilder)
}

protocol SendGenericBaseDataBuilder {
    func sendBuilder() throws -> SendBaseDataBuilder
    func stakingBuilder() throws -> StakingBaseDataBuilder
    func onrampBuilder() throws -> OnrampBaseDataBuilder
}

extension SendGenericBaseDataBuilder {
    func sendBuilder() throws -> SendBaseDataBuilder {
        guard let builder = self as? SendBaseDataBuilder else {
            throw SendBaseDataBuilderError.notFound("SendBaseDataBuilder")
        }
        return builder
    }

    func stakingBuilder() throws -> StakingBaseDataBuilder {
        guard let builder = self as? StakingBaseDataBuilder else {
            throw SendBaseDataBuilderError.notFound("StakingBaseDataBuilder")
        }
        return builder
    }

    func onrampBuilder() throws -> OnrampBaseDataBuilder {
        guard let builder = self as? OnrampBaseDataBuilder else {
            throw SendBaseDataBuilderError.notFound("OnrampBaseDataBuilder")
        }
        return builder
    }
}

enum SendBaseDataBuilderError: LocalizedError {
    case notFound(String)

    var errorDescription: String? {
        switch self {
        case .notFound(let string):
            "\(string) not found"
        }
    }
}
