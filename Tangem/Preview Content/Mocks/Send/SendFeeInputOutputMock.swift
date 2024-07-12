//
//  SendFeeInputOutputMock.swift
//  Tangem
//
//  Created by Andrey Chukavin on 01.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BlockchainSdk

class SendFeeInputOutputMock: SendFeeInput, SendFeeOutput {
    var selectedFee: SendFee? { SendFee(option: .market, value: .loaded(.init(.init(with: .polygon(testnet: false), value: 0.1)))) }
    var selectedFeePublisher: AnyPublisher<SendFee?, Never> { .just(output: selectedFee) }
    var cryptoAmountPublisher: AnyPublisher<BlockchainSdk.Amount, Never> { .just(output: .init(with: .polygon(testnet: false), value: 1)) }
    var destinationAddressPublisher: AnyPublisher<String?, Never> { .just(output: "0x") }

    func feeDidChanged(fee: SendFee) {}
}
