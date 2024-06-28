//
//  SendSummaryInteractor.swift
//  Tangem
//
//  Created by Sergey Balashov on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

protocol SendSummaryInput: AnyObject {
    var transactionPublisher: AnyPublisher<BlockchainSdk.Transaction?, Never> { get }
}

protocol SendSummaryOutput: AnyObject {}

protocol SendSummaryInteractor: AnyObject {
    var transactionDescription: AnyPublisher<String?, Never> { get }
}

class CommonSendSummaryInteractor {
    private weak var input: SendSummaryInput?
    private weak var output: SendSummaryOutput?

    private let sendTransactionSender: SendTransactionSender
    private let descriptionBuilder: SendTransactionSummaryDescriptionBuilder

    init(
        input: SendSummaryInput,
        output: SendSummaryOutput,
        sendTransactionSender: SendTransactionSender,
        descriptionBuilder: SendTransactionSummaryDescriptionBuilder
    ) {
        self.input = input
        self.output = output
        self.sendTransactionSender = sendTransactionSender
        self.descriptionBuilder = descriptionBuilder
    }
}

extension CommonSendSummaryInteractor: SendSummaryInteractor {
    var isSending: AnyPublisher<Bool, Never> {
        sendTransactionSender.isSending
    }

    var transactionDescription: AnyPublisher<String?, Never> {
        guard let input else { return Empty().eraseToAnyPublisher() }

        return input
            .transactionPublisher
            .withWeakCaptureOf(self)
            .map { interactor, transaction in
                transaction.flatMap { transaction in
                    interactor.descriptionBuilder.makeDescription(
                        amount: transaction.amount.value,
                        fee: transaction.fee.amount.value
                    )
                }
            }
            .eraseToAnyPublisher()
    }
}
