//
//  CardanoStakeKitTransactionHelper.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 25.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import SwiftCBOR

// import PotentCBOR

struct CardanoStakeKitTransactionHelper {
    private let transactionBuilder: CardanoTransactionBuilder

    init(transactionBuilder: CardanoTransactionBuilder) {
        self.transactionBuilder = transactionBuilder
    }

    func prepareForSign(_ unsignedData: String) throws -> Data {
        let data = Data(hex: unsignedData.addHexPrefix())
        let bytes = data.bytes
//        let cbor = try CBORDecoder().decode(CBORTransaction.self, from: data)

        let data2 = Data(hex: unsignedData)
        let cbo3 = try CBOR.decode(data2.bytes)

        let bytes2 = unsignedData.data(using: .utf8)!.bytes
        let cbo2 = try CBOR.decode(bytes2)
        return Data()

//        let rawData = try Protocol_Transaction.raw(serializedData: Data(hex: unsignedData))
//        let hash = try rawData.serializedData().sha256()
//        return .init(rawData: rawData, hash: hash)
    }
}

// MARK: - Main struct

struct CBORTransaction: Codable {
    let inputs: [String]
    let outputs: [Output]
    let fee: String
    let auxiliaryScripts: String?
    let certificates: [Certificate]
    let collateralInputs: [String]
    let currentTreasuryValue: String?
    let era: String
    let governanceActions: [String]
    let metadata: String?
    let mint: String?
    let redeemers: [String]
    let referenceInputs: [String]
    let requiredSigners: String?
    let returnCollateral: String?
    let totalCollateral: String?
    let treasuryDonation: Int
    let updateProposal: String?
    let validityRange: ValidityRange
    let voters: [String: String]
    let withdrawals: String?
    let witnesses: [String]
}

// MARK: - Certificate

struct Certificate: Codable {
    let stakeAddressDelegation: StakeAddressDelegation

    enum CodingKeys: String, CodingKey {
        case stakeAddressDelegation = "Stake address delegation"
    }
}

// MARK: - StakeAddressDelegation

struct StakeAddressDelegation: Codable {
    let delegatee: Delegatee
    let stakeCredential: StakeCredential

    enum CodingKeys: String, CodingKey {
        case delegatee
        case stakeCredential = "stake credential"
    }
}

// MARK: - Delegatee

struct Delegatee: Codable {
    let delegateeType: String
    let keyHash: String

    enum CodingKeys: String, CodingKey {
        case delegateeType = "delegatee type"
        case keyHash = "key hash"
    }
}

// MARK: - StakeCredential

struct StakeCredential: Codable {
    let keyHash: String

    enum CodingKeys: String, CodingKey {
        case keyHash
    }
}

// MARK: - Output

struct Output: Codable {
    let address: String
    let addressEra: String
    let amount: CBORAmount
    let network: String
    let paymentCredentialKeyHash: String
    let referenceScript: String?
    let stakeReference: StakeReference

    enum CodingKeys: String, CodingKey {
        case address
        case addressEra = "address era"
        case amount
        case network
        case paymentCredentialKeyHash = "payment credential key hash"
        case referenceScript
        case stakeReference = "stake reference"
    }
}

// MARK: - Amount

struct CBORAmount: Codable {
    let lovelace: Int
}

// MARK: - StakeReference

struct StakeReference: Codable {
    let stakeCredentialKeyHash: String

    enum CodingKeys: String, CodingKey {
        case stakeCredentialKeyHash = "stake credential key hash"
    }
}

// MARK: - ValidityRange

struct ValidityRange: Codable {
    let lowerBound: String?
    let upperBound: String?

    enum CodingKeys: String, CodingKey {
        case lowerBound = "lower bound"
        case upperBound = "upper bound"
    }
}
