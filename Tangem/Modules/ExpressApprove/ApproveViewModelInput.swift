//
//  ApproveViewModelInput.swift
//  Tangem
//
//  Created by Sergey Balashov on 08.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

protocol ApproveViewModelInput {
    var approveFeeValue: LoadingValue<Fee> { get }
    var approveFeeValuePublisher: AnyPublisher<LoadingValue<Fee>, Never> { get }

    func updateApprovePolicy(policy: ApprovePolicy)
    func sendApproveTransaction() async throws
}
