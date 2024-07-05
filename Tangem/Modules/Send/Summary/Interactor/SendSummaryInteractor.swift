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

    func setup(input: SendSummaryInput, output: SendSummaryOutput)
}

class CommonSendSummaryInteractor {
    private weak var input: SendSummaryInput?
    private weak var output: SendSummaryOutput?

    private let sendTransactionDispatcher: SendTransactionDispatcher
    private let descriptionBuilder: SendTransactionSummaryDescriptionBuilder

    private let _transactionDescription: CurrentValueSubject<String?, Never> = .init(.none)
    private var transactionDescriptionSubscribtion: AnyCancellable?

    init(
        input: SendSummaryInput,
        output: SendSummaryOutput,
        sendTransactionDispatcher: SendTransactionDispatcher,
        descriptionBuilder: SendTransactionSummaryDescriptionBuilder
    ) {
        self.input = input
        self.output = output
        self.sendTransactionDispatcher = sendTransactionDispatcher
        self.descriptionBuilder = descriptionBuilder
    }

extension CommonSendSummaryInteractor: SendSummaryInteractor {
    var isSending: AnyPublisher<Bool, Never> {
        sendTransactionDispatcher.isSending
    }

    var transactionDescription: AnyPublisher<String?, Never> {
        guard let input else { return Empty().eraseToAnyPublisher() }

        return input
            .transactionPublisher
            .withWeakCaptureOf(self)
            .sink { interactor, transaction in
                let description = transaction.flatMap { transaction in
                    interactor.descriptionBuilder.makeDescription(
                        amount: transaction.amount.value,
                        fee: transaction.fee.amount.value
                    )
                }

                interactor._transactionDescription.send(description)
            }
    }
}

extension CommonSendSummaryInteractor: SendSummaryInteractor {
    func setup(input: any SendSummaryInput, output _: any SendSummaryOutput) {
        bind(input: input)
    }

    var isSending: AnyPublisher<Bool, Never> {
        sendTransactionSender.isSending
    }

    var transactionDescription: AnyPublisher<String?, Never> {
        return _transactionDescription.eraseToAnyPublisher()
    }
}
