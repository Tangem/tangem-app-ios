//
//  KeysRepository.swift
//  Tangem
//
//  Created by Alexander Osokin on 20.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol KeysRepository: AnyObject, KeysProvider {
    func update(keys: [CardDTO.Wallet])
}

protocol KeysProvider {
    var keys: [CardDTO.Wallet] { get }
    var keysPublisher: AnyPublisher<[CardDTO.Wallet], Never> { get }
}

class CommonKeysRepository {
    private var _keys: CurrentValueSubject<[CardDTO.Wallet], Never>

    init(with keys: [CardDTO.Wallet]) {
        _keys = .init(keys)
    }
}

extension CommonKeysRepository: KeysRepository {
    var keys: [CardDTO.Wallet] {
        _keys.value
    }

    var keysPublisher: AnyPublisher<[CardDTO.Wallet], Never> {
        _keys.eraseToAnyPublisher()
    }

    func update(keys: [CardDTO.Wallet]) {
        _keys.value = keys
    }
}
