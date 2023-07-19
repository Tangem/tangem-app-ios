//
//  WalletManagersRepository.swift
//  Tangem
//
//  Created by Alexander Osokin on 26.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

protocol WalletManagersRepository {
    var signatureCountValidator: SignatureCountValidator? { get }
    var walletManagersPublisher: AnyPublisher<[BlockchainNetwork: any WalletManager], Never> { get }
}
