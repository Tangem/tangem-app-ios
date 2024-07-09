//
//  SendBaseInteractor.swift
//  Tangem
//
//  Created by Sergey Balashov on 27.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

protocol SendBaseInteractor {
    var isLoading: AnyPublisher<Bool, Never> { get }

    func send() -> AnyPublisher<SendTransactionDispatcherResult, Never>
    func makeMailData(transaction: BSDKTransaction, error: SendTxError) -> (dataCollector: EmailDataCollector, recipient: String)
}

class CommonSendBaseInteractor {
    private let input: SendBaseInput
    private let output: SendBaseOutput

    private let walletModel: WalletModel
    private let emailDataProvider: EmailDataProvider

    init(
        input: SendBaseInput,
        output: SendBaseOutput,
        walletModel: WalletModel,
        emailDataProvider: EmailDataProvider
    ) {
        self.input = input
        self.output = output
        self.walletModel = walletModel
        self.emailDataProvider = emailDataProvider
    }
}

extension CommonSendBaseInteractor: SendBaseInteractor {
    var isLoading: AnyPublisher<Bool, Never> {
        input.isLoading
    }

    func send() -> AnyPublisher<SendTransactionDispatcherResult, Never> {
        output.sendTransaction()
    }

    func makeMailData(transaction: BSDKTransaction, error: SendTxError) -> (dataCollector: EmailDataCollector, recipient: String) {
        let emailDataCollector = SendScreenDataCollector(
            userWalletEmailData: emailDataProvider.emailData,
            walletModel: walletModel,
            fee: transaction.fee.amount,
            destination: transaction.destinationAddress,
            amount: transaction.amount,
            isFeeIncluded: input.isFeeIncluded,
            lastError: error
        )

        let recipient = emailDataProvider.emailConfig?.recipient ?? EmailConfig.default.recipient

        return (dataCollector: emailDataCollector, recipient: recipient)
    }
}
