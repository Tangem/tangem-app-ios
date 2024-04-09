//
//  SendFiatCryptoAdapter.swift
//  Tangem
//
//  Created by Andrey Chukavin on 22.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SendFiatCryptoAdapterInput: AnyObject {
    var amountPublisher: AnyPublisher<Decimal?, Never> { get }

    func setUserInputAmount(_ userInputAmount: Decimal?)
}

protocol SendFiatCryptoAdapterOutput: AnyObject {
    func setAmount(_ decimal: Decimal?)
}

protocol SendFiatCryptoAdapter: AnyObject {
    var formattedAmountAlternativePublisher: AnyPublisher<String?, Never> { get }

    func setInput(_ input: SendFiatCryptoAdapterInput)
    func setOutput(_ output: SendFiatCryptoAdapterOutput)
    func setAmount(_ decimal: Decimal?)
    func setUseFiatCalculation(_ useFiatCalculation: Bool)
    func setCrypto(_ decimal: Decimal?)
}
