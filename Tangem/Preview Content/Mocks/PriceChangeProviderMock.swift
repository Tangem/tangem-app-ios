//
//  PriceChangeProviderMock.swift
//  Tangem
//
//  Created by Andrew Son on 01/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class PriceChangeProviderMock: PriceChangeProvider {
    var priceChangePublisher: AnyPublisher<Void, Never> { .just }

    func change(for currencyCode: String, in blockchain: Blockchain) -> Double {
        0
    }
}
