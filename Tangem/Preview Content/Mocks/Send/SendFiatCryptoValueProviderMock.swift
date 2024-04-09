//
//  SendFiatCryptoValueProviderMock.swift
//  Tangem
//
//  Created by Andrey Chukavin on 22.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class SendFiatCryptoValueProviderMock: SendFiatCryptoValueProvider {
    var formattedAmount: String? { "100 USDT" }
    var formattedAmountAlternative: String? { "100 $" }

    var formattedAmountPublisher: AnyPublisher<String?, Never> { .just(output: formattedAmount) }
    var formattedAmountAlternativePublisher: AnyPublisher<String?, Never> { .just(output: formattedAmountAlternative) }
}
