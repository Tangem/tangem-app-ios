//
//  SendSummaryViewModelInputMock.swift
//  Tangem
//
//  Created by Andrey Chukavin on 01.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BlockchainSdk

class SendSummaryViewModelInputMock: SendSummaryViewModelInput {
    var amountPublisher: AnyPublisher<SendAmount?, Never> { .just(output: .none) }
    var transactionAmountPublisher: AnyPublisher<Amount?, Never> { .just(output: nil) }
    var destinationTextPublisher: AnyPublisher<String, Never> { .just(output: "0x1f9090aaE28b8a3dCeaDf281B0F12828e676c326") }
    var additionalFieldPublisher: AnyPublisher<DestinationAdditionalFieldType, Never> { .just(output: .filled(type: .memo, value: "123123", params: TONTransactionParams(memo: "123123"))) }
    var feeValues: AnyPublisher<[SendFee], Never> { .just(output: []) }
    var selectedFeePublisher: AnyPublisher<SendFee?, Never> {
        .just(output: .init(option: .fast, value: .loaded(Fee(Amount(with: .ethereum(testnet: false), value: 0.003)))))
    }

    var amountText: String { "100,00" }
    var canEditAmount: Bool { true }
    var canEditDestination: Bool { true }
    var destinationTextBinding: Binding<String> { .constant("0x0123123") }
    var feeTextPublisher: AnyPublisher<String?, Never> { .just(output: "0.1 ETH") }
    var isSending: AnyPublisher<Bool, Never> { .just(output: false) }
}
