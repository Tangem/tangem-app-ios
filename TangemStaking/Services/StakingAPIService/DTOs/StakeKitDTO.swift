//
//  StakeKitDTO.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 24.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct StakeKitAPIError: Decodable, LocalizedError {
    public let code: String?
    public let message: String?
    let level: String?

    public var errorDescription: String? { message }
}

enum StakeKitDTO {
    // MARK: - Common

    struct Token: Codable {
        let network: String
        let name: String
        let decimals: Int
        let address: String?
        let symbol: String
    }

    struct Validator: Decodable {
        let address: String
        let status: Status
        let name: String?
        let image: String?
        let website: String?
        let apr: Decimal?
        let commission: Decimal?
        let stakedBalance: String?
        let votingPower: Decimal?
        let preferred: Bool?

        enum Status: String, Decodable {
            case active
            case jailed
            case deactivating
            case inactive
            case full
        }
    }

    struct Address: Codable {
        let address: String
        let additionalAddresses: AdditionalAddresses?

        init(address: String, additionalAddresses: StakeKitDTO.Address.AdditionalAddresses? = nil) {
            self.address = address
            self.additionalAddresses = additionalAddresses
        }

        struct AdditionalAddresses: Codable {
            let cosmosPubKey: String?
            let binanceBeaconAddress: String?
            let stakeAccounts: [String]?
            let lidoStakeAccounts: [String]?
            let tezosPubKey: String?
            let cAddressBech: String?
            let pAddressBech: String?

            init(
                cosmosPubKey: String? = nil,
                binanceBeaconAddress: String? = nil,
                stakeAccounts: [String]? = nil,
                lidoStakeAccounts: [String]? = nil,
                tezosPubKey: String? = nil,
                cAddressBech: String? = nil,
                pAddressBech: String? = nil
            ) {
                self.cosmosPubKey = cosmosPubKey
                self.binanceBeaconAddress = binanceBeaconAddress
                self.stakeAccounts = stakeAccounts
                self.lidoStakeAccounts = lidoStakeAccounts
                self.tezosPubKey = tezosPubKey
                self.cAddressBech = cAddressBech
                self.pAddressBech = pAddressBech
            }
        }
    }

    struct Action: Decodable {
        let addresses: Address
        let amount: String?
        let createdAt: String?
        let currentStepIndex: Int
        let id: String
        let inputToken: Token?
        let integrationId: String
        let status: StakeKitDTO.Actions.ActionStatus
        let tokenId: String?
        let transactions: [Transaction.Response]
        let type: Actions.ActionType
        let USDAmount: String?
        let validatorAddress: String?
        let validatorAddresses: [String]?
        let accountAddresses: [String]?
    }

    struct Required: Decodable {
        let required: Bool
    }
}
