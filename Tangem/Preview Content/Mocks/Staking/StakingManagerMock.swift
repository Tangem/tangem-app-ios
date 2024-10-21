//
//  StakingManagerMock.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking

class StakingManagerMock: StakingManager {
    var state: StakingManagerState { .notEnabled }
    var statePublisher: AnyPublisher<StakingManagerState, Never> { .just(output: state) }
    var allowanceAddress: String? { nil }
    var actionsPublisher: AnyPublisher<[PendingAction], Never> { .just(output: []) }

    func updateState() async {}
    func actions() async {}
    func estimateFee(action: StakingAction) async throws -> Decimal { .zero }
    func transaction(action: StakingAction) async throws -> StakingTransactionAction { .mock }
    func transactionDidSent(action: StakingAction) {}
}
