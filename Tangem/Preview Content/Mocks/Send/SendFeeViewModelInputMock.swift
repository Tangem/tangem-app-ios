//
//  SendFeeViewModelInputMock.swift
//  Tangem
//
//  Created by Andrey Chukavin on 01.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BigInt
import BlockchainSdk

class SendFeeViewModelInputMock: SendFeeViewModelInput {
    var customFeePublisher: AnyPublisher<Fee?, Never> {
        .just(output: nil)
    }

    var amountPublisher: AnyPublisher<Amount?, Never> {
        .just(output: nil)
    }

    var selectedFeeOption: FeeOption {
        .market
    }

    var feeOptions: [FeeOption] {
        [.slow, .market, .fast, .custom]
    }

    var feeValues: AnyPublisher<[FeeOption: LoadingValue<Fee>], Never> {
        .just(output: [
            .slow: .loaded(.init(.init(with: .ethereum(testnet: false), type: .coin, value: 1))),
            .market: .loaded(.init(.init(with: .ethereum(testnet: false), type: .coin, value: 2))),
            .fast: .loaded(.init(.init(with: .ethereum(testnet: false), type: .coin, value: 3))),
        ])
    }

    var canIncludeFeeIntoAmount: Bool {
        true
    }

    var isFeeIncludedPublisher: AnyPublisher<Bool, Never> {
        .just(output: false)
    }

    func didSelectFeeOption(_ feeOption: FeeOption) {}
}
