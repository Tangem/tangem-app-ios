//
//  VisaBridgeInteractor.swift
//  TangemVisa
//
//  Created by Andrew Son on 15/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

public protocol VisaBridgeInteractor {
    var visaToken: Token { get }
    var accountAddress: String { get }
    func loadBalances() async throws -> VisaBalances
    func loadLimits() async throws -> VisaLimits
}
