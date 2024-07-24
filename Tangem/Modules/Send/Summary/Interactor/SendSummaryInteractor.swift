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

protocol SendSummaryInteractor: AnyObject {
    var transactionDescription: AnyPublisher<String?, Never> { get }
}

class CommonSendSummaryInteractor {
    private weak var input: SendSummaryInput?
    private weak var output: SendSummaryOutput?

    private let sendTransactionDispatcher: SendTransactionDispatcher
    private let descriptionBuilder: SendTransactionSummaryDescriptionBuilder
    private let blockchain: Blockchain

    init(
        input: SendSummaryInput,
        output: SendSummaryOutput,
        sendTransactionDispatcher: SendTransactionDispatcher,
        descriptionBuilder: SendTransactionSummaryDescriptionBuilder,
        blockchain: Blockchain
    ) {
        self.input = input
        self.output = output
        self.sendTransactionDispatcher = sendTransactionDispatcher
        self.descriptionBuilder = descriptionBuilder
        self.blockchain = blockchain
    }

    private func mapToDescription(transaction: SendTransactionType) -> String? {
        switch transaction {
        case .transfer(let bsdkTransaction):
            let isNoFiatFee = switch blockchain.feePaidCurrency {
            case .feeResource:
                true
            default:
                false
            }

            return descriptionBuilder.makeDescription(
                amount: bsdkTransaction.amount.value,
                fee: bsdkTransaction.fee.amount.value,
                isNoFiatFee: isNoFiatFee
            )
        case .staking(let stakingTransaction):
            return nil // Waiting texts
        }
    }
}

extension CommonSendSummaryInteractor: SendSummaryInteractor {
    var isSending: AnyPublisher<Bool, Never> {
        sendTransactionDispatcher.isSending
    }

    var transactionDescription: AnyPublisher<String?, Never> {
        guard let input else {
            assertionFailure("SendFeeInput is not found")
            return Empty().eraseToAnyPublisher()
        }

        return input
            .transactionPublisher
            .withWeakCaptureOf(self)
            .map { interactor, transaction in
                transaction.flatMap { transaction in
                    interactor.mapToDescription(transaction: transaction)
                }
            }
            .eraseToAnyPublisher()
    }
}
