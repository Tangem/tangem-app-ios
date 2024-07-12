//
//  StakeKitDTO+Balances.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 12.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension StakeKitDTO {
    enum Balances {
        struct Request: Encodable {
            let addresses: Address
            let network: NetworkType
        }

        struct Response: Decodable {
            let balances: [Balance]
            let integrationId: String?

            struct Balance: Decodable {
                let groupId: String
                let type: BalanceType
                let amount: Decimal
                let date: Date?
                let pricePerShare: Decimal
                let pendingActions: [PendingAction]
                let token: Token
                let validatorAddress: String?
                let validatorAddresses: [String]?
                let providerId: String?

                enum BalanceType: String, Decodable {
                    case available = "AVAILABLE"
                    case staked = "STAKED"
                    case unstaking = "UNSTAKING"
                    case unstaked = "UNSTAKED"
                    case preparing = "PREPARING"
                    case rewards = "REWARDS"
                    case locked = "LOCKED"
                    case unlocking = "UNLOCKING"
                    case unknown = "UNKNOWN"
                }

                struct PendingAction: Decodable {
                    let type: Actions.ActionType
                    let passthrough: String
                    let args: Actions.ActionArgs?
                }
            }
        }
    }
}
