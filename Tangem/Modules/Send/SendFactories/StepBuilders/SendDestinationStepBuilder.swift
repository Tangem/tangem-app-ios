//
//  SendDestinationStepBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct SendDestinationStepBuilder {
    typealias ReturnValue = (step: SendDestinationStep, interactor: SendDestinationInteractor)

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    let walletModel: WalletModel
    let builder: SendModulesStepsBuilder

    func makeSendDestinationStep(
        sendAmountInteractor: any SendAmountInteractor,
        sendFeeInteractor: any SendFeeInteractor,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        router: SendDestinationRoutable
    ) -> ReturnValue {
        let interactor = makeSendDestinationInteractor()

        let viewModel = makeSendDestinationViewModel(
            interactor: interactor,
            addressTextViewHeightModel: addressTextViewHeightModel
        )

        let step = SendDestinationStep(
            viewModel: viewModel,
            interactor: interactor,
            sendAmountInteractor: sendAmountInteractor,
            sendFeeInteractor: sendFeeInteractor,
            tokenItem: walletModel.tokenItem,
            router: router
        )

        return (step: step, interactor: interactor)
    }
}

// MARK: - SendAmountStepBuilder

private extension SendDestinationStepBuilder {
    func makeSendDestinationViewModel(
        interactor: SendDestinationInteractor,
        addressTextViewHeightModel: AddressTextViewHeightModel
    ) -> SendDestinationViewModel {
        let tokenItem = walletModel.tokenItem
        let suggestedWallets = builder.makeSuggestedWallets(userWalletModels: userWalletRepository.models)
        let additionalFieldType = SendAdditionalFields.fields(for: tokenItem.blockchain)
        let settings = SendDestinationViewModel.Settings(
            networkName: tokenItem.networkName,
            additionalFieldType: additionalFieldType,
            suggestedWallets: suggestedWallets
        )

        let viewModel = SendDestinationViewModel(
            settings: settings,
            interactor: interactor,
            addressTextViewHeightModel: addressTextViewHeightModel
        )

        //        let address = sendType.predefinedDestination.map { SendAddress(value: $0, source: .sellProvider) }
        //        viewModel.setExternally(address: address, additionalField: sendType.predefinedTag)

        return viewModel
    }

    func makeSendDestinationInteractor() -> SendDestinationInteractor {
        CommonSendDestinationInteractor(
            validator: makeSendDestinationValidator(),
            transactionHistoryProvider: makeSendDestinationTransactionHistoryProvider(),
            transactionHistoryMapper: makeTransactionHistoryMapper(),
            addressResolver: walletModel.addressResolver,
            additionalFieldType: .fields(for: walletModel.tokenItem.blockchain),
            parametersBuilder: makeSendTransactionParametersBuilder()
        )
    }

    func makeSendTransactionParametersBuilder() -> SendTransactionParametersBuilder {
        SendTransactionParametersBuilder(blockchain: walletModel.tokenItem.blockchain)
    }

    func makeSendDestinationValidator() -> SendDestinationValidator {
        let addressService = AddressServiceFactory(blockchain: walletModel.wallet.blockchain).makeAddressService()
        let validator = CommonSendDestinationValidator(
            walletAddresses: walletModel.addresses,
            addressService: addressService,
            supportsCompound: walletModel.wallet.blockchain.supportsCompound
        )

        return validator
    }

    func makeSendDestinationTransactionHistoryProvider() -> SendDestinationTransactionHistoryProvider {
        CommonSendDestinationTransactionHistoryProvider(walletModel: walletModel)
    }

    func makeTransactionHistoryMapper() -> TransactionHistoryMapper {
        TransactionHistoryMapper(
            currencySymbol: walletModel.tokenItem.currencySymbol,
            walletAddresses: walletModel.addresses,
            showSign: false
        )
    }
}

private extension Blockchain {
    var supportsCompound: Bool {
        switch self {
        case .bitcoin,
             .bitcoinCash,
             .litecoin,
             .dogecoin,
             .dash,
             .kaspa,
             .ravencoin,
             .ducatus:
            return true
        default:
            return false
        }
    }
}
