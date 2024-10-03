//
//  SendAmountModifier.swift
//  TangemApp
//
//  Created by Sergey Balashov on 17.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SendAmountModifier {
    var modifyingMessagePublisher: AnyPublisher<String?, Never> { get }

    func modify(cryptoAmount: Decimal?) -> Decimal?
}

struct StakingAmountModifier: SendAmountModifier {
    private let tokenItem: TokenItem

    private var _message: CurrentValueSubject<String?, Never> = .init(nil)

    init(tokenItem: TokenItem) {
        self.tokenItem = tokenItem
    }

    var modifyingMessagePublisher: AnyPublisher<String?, Never> {
        _message.eraseToAnyPublisher()
    }

    func modify(cryptoAmount amount: Decimal?) -> Decimal? {
        guard let crypto = amount, tokenItem.hasToBeRounded else {
            _message.send(.none)
            return amount
        }

        let rounded = crypto.rounded()
        let isFloat = rounded != crypto

        guard isFloat else {
            _message.send(nil)
            return amount
        }

        _message.send(Localization.stakingAmountTronIntegerError(rounded))
        return rounded
    }
}

private extension TokenItem {
    var hasToBeRounded: Bool {
        switch blockchain {
        case .tron: true
        default: false
        }
    }
}
