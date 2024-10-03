//
//  PendingActionRequest.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 10.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct PendingActionRequest {
    public let request: ActionGenericRequest
    public let passthrough: String
    public let type: StakingAction.PendingActionType

    public init(
        request: ActionGenericRequest,
        passthrough: String,
        type: StakingAction.PendingActionType
    ) {
        self.request = request
        self.passthrough = passthrough
        self.type = type
    }
}
