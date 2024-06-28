//
//  SendSummaryInputOutputMock.swift
//  Tangem
//
//  Created by Andrey Chukavin on 01.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BlockchainSdk

class SendSummaryInputOutputMock: SendSummaryInput, SendSummaryOutput {
    var transactionPublisher: AnyPublisher<BlockchainSdk.Transaction?, Never> { .just(output: nil) }
}

class SendSummaryInteractorMock: SendSummaryInteractor {
    var transactionDescription: AnyPublisher<String?, Never> { .just(output: "123124$ (34151 USDT)") }

    var isSending: AnyPublisher<Bool, Never> { .just(output: false) }
}
