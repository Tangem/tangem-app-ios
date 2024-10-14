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

    private let descriptionBuilder: SendTransactionSummaryDescriptionBuilder

    init(
        input: SendSummaryInput,
        output: SendSummaryOutput,
        descriptionBuilder: SendTransactionSummaryDescriptionBuilder
    ) {
        self.input = input
        self.output = output
        self.descriptionBuilder = descriptionBuilder
    }
}

extension CommonSendSummaryInteractor: SendSummaryInteractor {
    var transactionDescription: AnyPublisher<String?, Never> {
        guard let input else {
            assertionFailure("SendFeeInput is not found")
            return Empty().eraseToAnyPublisher()
        }

        return input
            .summaryTransactionDataPublisher
            .withWeakCaptureOf(self)
            .map { interactor, transactionData in
                transactionData.flatMap {
                    interactor.descriptionBuilder.makeDescription(transactionType: $0)
                }
            }
            .eraseToAnyPublisher()
    }
}
