//
//  StakeKitDTO+Actions.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 27.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension StakeKitDTO {
    enum Actions {
        enum ActionType: String, Hashable, Codable {
            case stake = "STAKE"
            case unstake = "UNSTAKE"
            case claimRewards = "CLAIM_REWARDS"
            case restakeRewards = "RESTAKE_REWARDS"
            case withdraw = "WITHDRAW"
            case restake = "RESTAKE"
            case claimUnstaked = "CLAIM_UNSTAKED"
            case unlockLocked = "UNLOCK_LOCKED"
            case stakeLocked = "STAKE_LOCKED"
            case vote = "VOTE"
            case revoke = "REVOKE"
            case voteLocked = "VOTE_LOCKED"
            case revote = "REVOTE"
            case rebond = "REBOND"
            case migrate = "MIGRATE"
        }

        enum ActionStatus: String, Hashable, Codable {
            case canceled = "CANCELED"
            case created = "CREATED"
            case waitingForNext = "WAITING_FOR_NEXT"
            case processing = "PROCESSING"
            case failed = "FAILED"
            case success = "SUCCESS"
        }

        struct ActionArgs: Decodable {
            let amount: Amount?
            let duration: Duration?
            let validatorAddress: Required?
            let validatorAddresses: Required?
            let nfts: [NFT]?
            let tronResource: TronResource?
            let signatureVerification: Required?

            struct Amount: Decodable {
                let required: Bool
                let minimum: Decimal
                let maximum: Decimal?
            }

            struct Duration: Codable {
                let required: Bool
                let minimum: Int?
                let maximum: Int?
            }

            struct NFT: Decodable {
                let baycId: Required?
                let maycId: Required?
                let bakcId: Required?
            }

            enum TronResource: String, Codable {
                case energy = "ENERGY"
                case bandwidth = "BANDWIDTH"
            }
        }

        enum Get {
            struct Request: Encodable {
                let actionId: String
            }

            struct Response: Decodable {}
        }

        enum Enter {
            struct Request: Encodable {
                let integrationId: String
                let addresses: Address
                let args: Args
            }

            struct Response: Decodable {
                let id: String
                let integrationId: String
                let status: ActionStatus
                let type: ActionType
                let currentStepIndex: Int
                let amount: String
                let validatorAddress: String?
                let validatorAddresses: [String]?
                let transactions: [Transaction.Response]?
            }
        }

        enum Exit {
            struct Request: Encodable {
                let integrationId: String
                let addresses: Address
                let args: Args
            }

            struct Response: Decodable {
                let id: String
                let integrationId: String
                let status: ActionStatus
                let type: ActionType
                let currentStepIndex: Int
                let amount: String
                let validatorAddress: String?
                let validatorAddresses: [String]?
                let transactions: [Transaction.Response]?
            }
        }

        enum Pending {
            struct Request: Encodable {
                let type: Actions.ActionType
                let integrationId: String
                let passthrough: String
                let addresses: Address
                let args: Args
            }

            struct Response: Decodable {
                let id: String
                let integrationId: String
                let status: ActionStatus
                let type: ActionType
                let currentStepIndex: Int
                let amount: String
                let validatorAddress: String?
                let validatorAddresses: [String]?
                let transactions: [Transaction.Response]?
            }
        }

        struct Args: Encodable {
            let amount: String
            let validatorAddress: String?
            let validatorAddresses: [String]?
            let inputToken: Token?
            let tronResource: String?

            init(
                amount: String,
                validatorAddress: String?,
                validatorAddresses: [String]?,
                inputToken: StakeKitDTO.Token? = nil,
                tronResource: String? = nil
            ) {
                self.amount = amount
                self.validatorAddress = validatorAddress
                self.validatorAddresses = validatorAddresses
                self.inputToken = inputToken
                self.tronResource = tronResource
            }
        }

        enum List {
            struct Request: Encodable {
                let walletAddress: String
                let network: StakeKitNetworkType
                let status: ActionStatus
                let limit: Int
                let sort: String
            }

            struct Response: Decodable {
                let page: Int
                let data: [Action]
                let hasNextPage: Bool
                let limit: Int
            }
        }
    }
}
