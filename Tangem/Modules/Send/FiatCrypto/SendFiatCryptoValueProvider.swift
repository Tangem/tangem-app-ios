//
//  SendFiatCryptoValueProvider.swift
//  Tangem
//
//  Created by Andrey Chukavin on 22.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SendFiatCryptoValueProvider: AnyObject {
    var formattedAmount: String? { get }
    var formattedAmountAlternative: String? { get }

    var formattedAmountPublisher: AnyPublisher<String?, Never> { get }
    var formattedAmountAlternativePublisher: AnyPublisher<String?, Never> { get }
}
