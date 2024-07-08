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
    typealias IO = (input: SendDestinationInput, output: SendDestinationOutput)
    typealias ReturnValue = (step: SendDestinationStep, interactor: SendDestinationInteractor)

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    let walletModel: WalletModel
    let builder: SendDependenciesBuilder

    func makeSendDestinationStep(
        io: IO,
        sendAmountInteractor: any SendAmountInteractor,
        sendFeeInteractor: any SendFeeInteractor,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        router: SendDestinationRoutable
    ) -> ReturnValue {
        let interactor = makeSendDestinationInteractor(io: io)

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
        let suggestedWallets = makeSuggestedWallets()
        let additionalFieldType = SendDestinationAdditionalFieldType.type(for: tokenItem.blockchain)

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

        return viewModel
    }

    func makeSendDestinationInteractor(io: IO) -> SendDestinationInteractor {
        CommonSendDestinationInteractor(
            input: io.input,
            output: io.output,
            validator: makeSendDestinationValidator(),
            transactionHistoryProvider: makeSendDestinationTransactionHistoryProvider(),
            transactionHistoryMapper: makeTransactionHistoryMapper(),
            addressResolver: walletModel.addressResolver,
            additionalFieldType: .type(for: walletModel.tokenItem.blockchain),
            parametersBuilder: builder.makeSendTransactionParametersBuilder()
        )
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

    func makeSuggestedWallets() -> [SendDestinationViewModel.Settings.SuggestedWallet] {
        userWalletRepository.models.reduce([]) { result, userWalletModel in
            let walletModels = userWalletModel.walletModelsManager.walletModels
            return result + walletModels
                .filter { walletModel in
                    let ignoredAddresses = self.walletModel.wallet.addresses.map { $0.value }

                    return walletModel.blockchainNetwork.blockchain.networkId == self.walletModel.tokenItem.blockchain.networkId &&
                        walletModel.isMainToken &&
                        !ignoredAddresses.contains(walletModel.defaultAddress)
                }
                .map { walletModel in
                    (name: userWalletModel.name, address: walletModel.defaultAddress)
                }
        }
    }
}
