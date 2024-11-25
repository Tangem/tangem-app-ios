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
            let network: StakeKitNetworkType
        }

        struct Response: Decodable {
            let balances: [Balance]
            let integrationId: String?

            struct Balance: Decodable {
                let accountAddress: String?
                let groupId: String
                let type: BalanceType
                let amount: String
                let date = Date()
                let pricePerShare: String
                let pendingActions: [PendingAction]
                let token: Token
                let validatorAddress: String?
                let validatorAddresses: [String]?
                let providerId: String?

                enum BalanceType: String, Decodable {
                    case available
                    case staked
                    case unstaking
                    case unstaked
                    case preparing
                    case rewards
                    case locked
                    case unlocking
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
