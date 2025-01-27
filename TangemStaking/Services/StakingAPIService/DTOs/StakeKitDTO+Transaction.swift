//
//  StakeKitDTO+Transaction.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 12.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension StakeKitDTO {
    enum SubmitTransaction {
        struct Request: Encodable {
            let signedTransaction: String
        }

        struct Response: Decodable {
            let transactionHash: String
            let link: String
        }
    }

    enum ConstructTransaction {
        struct Request: Encodable {
            let gasArgs: GasArgs?

            enum GasArgs: Encodable {
                case cosmos(gasPrice: String)
                case eip1559(type: Int = 2, maxFeePerGas: String, maxPriorityFeePerGas: String)
                case legacy(type: Int = 0, gasPrice: String)
            }
        }
    }

    enum Transaction {
        struct Request: Encodable {}

        struct Response: Decodable {
            let id: String
            let network: StakeKitNetworkType
            let status: Status
            let type: TransactionType
            let hash: String?
            let createdAt: Date?
            let signedTransaction: String?
            let unsignedTransaction: String?
            let stepIndex: Int
            let error: String?
            let gasEstimate: GasEstimate?
            let stakeId: String?
            let explorerUrl: String?
            let ledgerHwAppId: String?
            let isMessage: Bool

            enum Status: String, Decodable {
                case notFound = "NOT_FOUND"
                case created = "CREATED"
                case blocked = "BLOCKED"
                case waitingForSignature = "WAITING_FOR_SIGNATURE"
                case signed = "SIGNED"
                case broadcasted = "BROADCASTED"
                case pending = "PENDING"
                case confirmed = "CONFIRMED"
                case failed = "FAILED"
                case skipped = "SKIPPED"
            }

            enum TransactionType: String, Decodable {
                case swap = "SWAP"
                case deposit = "DEPOSIT"
                case approval = "APPROVAL"
                case stake = "STAKE"
                case claimUnstaked = "CLAIM_UNSTAKED"
                case claimRewards = "CLAIM_REWARDS"
                case restakeRewards = "RESTAKE_REWARDS"
                case unstake = "UNSTAKE"
                case split = "SPLIT"
                case merge = "MERGE"
                case lock = "LOCK"
                case unlock = "UNLOCK"
                case supply = "SUPPLY"
                case bridge = "BRIDGE"
                case vote = "VOTE"
                case revoke = "REVOKE"
                case restake = "RESTAKE"
                case rebond = "REBOND"
                case withdraw = "WITHDRAW"
                case createAccount = "CREATE_ACCOUNT"
                case reveal = "REVEAL"
                case migrate = "MIGRATE"
                case utxoPToCImport = "UTXO_P_TO_C_IMPORT"
                case utxoCToPImport = "UTXO_C_TO_P_IMPORT"
                case unfreezeLegacy = "UNFREEZE_LEGACY"
                case unfreezeLegacyBandwidth = "UNFREEZE_LEGACY_BANDWIDTH"
                case unfreezeLegacyEnergy = "UNFREEZE_LEGACY_ENERGY"
                case unfreezeBandwidth = "UNFREEZE_BANDWIDTH"
                case unfreezeEnergy = "UNFREEZE_ENERGY"
                case freezeBandwidth = "FREEZE_BANDWIDTH"
                case freezeEnergy = "FREEZE_ENERGY"
                case undelegateBandwidth = "UNDELEGATE_BANDWIDTH"
                case undelegateEnergy = "UNDELEGATE_ENERGY"
                case p2pNodeRequest = "P2P_NODE_REQUEST"
                case luganodesProvision = "LUGANODES_PROVISION"
                case luganodesExitRequest = "LUGANODES_EXIT_REQUEST"
                case infstonesProvision = "INFSTONES_PROVISION"
                case infstonesExitRequest = "INFSTONES_EXIT_REQUEST"
                case infstonesClaimRequest = "INFSTONES_CLAIM_REQUEST"
            }

            struct GasEstimate: Decodable {
                let gasLimit: String?
                let amount: String
                let token: Token?
            }
        }
    }
}

extension StakeKitDTO.Transaction {
    struct TronTransaction: Decodable {
        let rawDataHex: String
    }
}
