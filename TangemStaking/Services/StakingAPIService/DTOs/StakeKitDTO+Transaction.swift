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
            let network: NetworkType
            let status: Status
            let type: TransactionType
            let hash: String?
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
                case unknown = "UNKNOWN"
            }

            enum TransactionType: String, Decodable {
                case enter = "ENTER"
                case reinvest = "REINVEST"
                case exit = "EXIT"
                case claim = "CLAIM"
                case claimRewards = "CLAIM_REWARDS"
                case send = "SEND"
                case approve = "APPROVE"
                case unknown = "UNKNOWN"
            }

            struct GasEstimate: Decodable {
                let gasLimit: Decimal?
                let amount: Decimal?
                let token: Token?
            }
        }
    }
}
