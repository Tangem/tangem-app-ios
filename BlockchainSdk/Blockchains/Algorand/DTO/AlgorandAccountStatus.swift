//
//  AlgorandAccountStatus.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 12.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum AlgorandAccountStatus: String, Decodable {
    case offline = "Offline"
    case online = "Online"
    case notParticipating = "NotParticipating"
}
