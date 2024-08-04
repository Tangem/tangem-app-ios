//
//  ApproveService.swift
//  Tangem
//
//  Created by Sergey Balashov on 08.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemExpress

protocol ApproveService {
    var approveFeeValue: LoadingValue<Fee> { get }
    var approveFeeValuePublisher: AnyPublisher<LoadingValue<Fee>, Never> { get }

    func updateApprovePolicy(policy: ExpressApprovePolicy)
    func sendApproveTransaction() async throws
}
