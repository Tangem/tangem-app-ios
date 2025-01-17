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

    func prepareForSign(_ transaction: StakeKitTransaction) throws -> Data {
        let transaction = try cardanoTransaction(from: transaction.unsignedData)
        return try transactionBuilder.buildStakingForSign(transaction: transaction)
    }

    func prepareForSend(_ transaction: StakeKitTransaction, signature: SignatureInfo) throws -> Data {
        let transaction = try cardanoTransaction(from: transaction.unsignedData)
        return try transactionBuilder.buildStakingForSend(transaction: transaction, signatures: [signature])
    }

    private func cardanoTransaction(from unsignedData: String) throws -> CardanoTransaction {
        let data = Data(hex: unsignedData)
        guard let cbor = try CBOR.decode(data.bytes) else {
            throw WalletError.failedToBuildTx
        }

        guard let body = CardanoTransactionBody(cbor: cbor) else {
            throw WalletError.failedToBuildTx
        }

        return CardanoTransaction(body: body, witnessSet: nil, isValid: true, auxiliaryData: nil)
    }
}

// MARK: - Main struct

struct CardanoTransaction {
    let body: CardanoTransactionBody
    let witnessSet: Data?
    let isValid: Bool
    let auxiliaryData: Data?
}

struct CardanoTransactionBody {
    struct Input {
        let transactionID: String
        let index: UInt64

        init?(cbor: CBOR) {
            guard case .array(let inputInfo) = cbor, inputInfo.count == 2 else {
                return nil
            }

            guard case .byteString(let bytes) = inputInfo[0],
                  bytes.count == 32 else {
                return nil
            }

            guard case .unsignedInt(let uInt64) = inputInfo[1] else {
                return nil
            }

            transactionID = Data(bytes).hexString
            index = uInt64
        }
    }

    struct Output {
        let address: String
        let amount: UInt64

        init?(cbor: CBOR) {
            guard case .array(let outputInfo) = cbor,
                  outputInfo.count == 2 else {
                return nil
            }

            guard case .byteString(let bytes) = outputInfo[0] else { return nil }

            guard case .unsignedInt(let uInt64) = outputInfo[1] else { return nil }

            address = Data(bytes).hex
            amount = uInt64
        }
    }

    struct Credential {
        let keyHash: Data
    }

    struct StakeDelegation {
        let credential: Credential
        let poolKeyHash: Data

        init?(cbor: CBOR) {
            guard case .array(let certInfo) = cbor,
                  certInfo.count == 3 /* cert_index, stake_credential, pool_keyhash */ else {
                return nil
            }

            guard case .array(let credentials) = certInfo[1],
                  credentials.count == 2 else { // credential type, byte array
                return nil
            }

            guard case .unsignedInt(let credentialType) = credentials[0],
                  credentialType == 0 else { // 0 - key hash, 1 - script hash
                return nil
            }

            guard case .byteString(let keyHashArray) = credentials[1],
                  keyHashArray.count == 28 else { // 28 bytes ed key
                return nil
            }

            guard case .byteString(let poolKeyHashArray) = certInfo[2] else {
                return nil
            }

            credential = Credential(keyHash: Data(keyHashArray))
            poolKeyHash = Data(poolKeyHashArray)
        }
    }

    enum Certificate {
        case stakeRegistrationLegacy
        case stakeDeregistrationLegacy
        case stakeDelegation(StakeDelegation)
        case poolRegistration
        case poolRetirement
        case genesisKeyDelegation
        case moveInstantaneousRewardsCert
        case stakeRegistrationConway
        case stakeDeregistrationConway
        case voteDelegation
        case stakeAndVoteDelegation
        case stakeRegistrationAndDelegation
        case voteRegistrationAndDelegation
        case stakeVoteRegistrationAndDelegation
        case committeeHotAuth
        case committeeColdResign
        case dRepRegistration
        case dRepDeregistration
        case dRepUpdate

        enum Index: UInt64, RawRepresentable {
            case stakeRegistrationLegacy = 0
            case stakeDeregistrationLegacy
            case stakeDelegation
            case poolRegistration
            case poolRetirement
            case genesisKeyDelegation
            case moveInstantaneousRewardsCert
            case stakeRegistrationConway
            case stakeDeregistrationConway
            case voteDelegation
            case stakeAndVoteDelegation
            case stakeRegistrationAndDelegation
            case voteRegistrationAndDelegation
            case stakeVoteRegistrationAndDelegation
            case committeeHotAuth
            case committeeColdResign
            case dRepRegistration
            case dRepDeregistration
            case dRepUpdate
        }
    }

    let inputs: [Input]
    let outputs: [Output]
    let fee: Decimal
    let auxiliaryScripts: String?
    let certificates: [Certificate]
    let collateralInputs: [String]?
    let currentTreasuryValue: String?
    let era: String?
    let governanceActions: [String]?
    let metadata: String?
    let mint: String?
    let redeemers: [String]?
    let referenceInputs: [String]?
    let requiredSigners: String?
    let returnCollateral: String?
    let totalCollateral: String?
    let updateProposal: String?
    let voters: [String: String]?
    let withdrawals: String?
    let witnesses: [String]?
}

private extension CardanoTransactionBody {
    init?(cbor: CBOR) {
        guard case .array(let byteString) = cbor else {
            return nil
        }

        guard case .map(let map) = byteString.first else {
            return nil
        }

        var inputs: [Input]?
        var outputs: [Output]?
        var fee: Decimal?
        var certificates: [Certificate]?

        for (key, element) in map {
            guard case .unsignedInt(let uInt) = key else {
                continue
            }

            switch uInt {
            case 0: inputs = Self.parseInputs(element)
            case 1: outputs = Self.parseOutputs(element)
            case 2: fee = Self.parseFee(element)
            case 4: certificates = Self.parseCerts(element)
            default: continue
            }
        }

        guard let inputs, let outputs, let fee, let certificates else { return nil }

        self.init(
            inputs: inputs,
            outputs: outputs,
            fee: fee,
            auxiliaryScripts: nil,
            certificates: certificates,
            collateralInputs: nil,
            currentTreasuryValue: nil,
            era: nil,
            governanceActions: nil,
            metadata: nil,
            mint: nil,
            redeemers: nil,
            referenceInputs: nil,
            requiredSigners: nil,
            returnCollateral: nil,
            totalCollateral: nil,
            updateProposal: nil,
            voters: nil,
            withdrawals: nil,
            witnesses: nil
        )
    }

    private static func parseInputs(_ cbor: CBOR) -> [CardanoTransactionBody.Input]? {
        guard case .tagged(let tag, let cbor) = cbor, tag.rawValue == 258, case .array(let inputs) = cbor else {
            return nil
        }

        return inputs.compactMap { inputCBOR in
            CardanoTransactionBody.Input(cbor: inputCBOR)
        }
    }

    private static func parseOutputs(_ cbor: CBOR) -> [CardanoTransactionBody.Output]? {
        guard case .array(let outputs) = cbor else {
            return nil
        }

        return outputs.compactMap { outputCBOR in
            CardanoTransactionBody.Output(cbor: outputCBOR)
        }
    }

    private static func parseFee(_ cbor: CBOR) -> Decimal? {
        if case .unsignedInt(let uInt64) = cbor {
            return Decimal(uInt64)
        }
        return nil
    }

    private static func parseCerts(_ cbor: CBOR) -> [CardanoTransactionBody.Certificate]? {
        guard case .tagged(let tag, let cbor) = cbor, tag.rawValue == 258, case .array(let certs) = cbor else {
            return nil
        }

        return certs.compactMap { certCBOR -> CardanoTransactionBody.Certificate? in
            guard case .array(let certInfo) = certCBOR,
                  certInfo.count == 3 /* cert_index, stake_credential, pool_keyhash */ else {
                return nil
            }

            guard case .unsignedInt(let index) = certInfo[0] else { return nil }

            switch index {
            case CardanoTransactionBody.Certificate.Index.stakeDelegation.rawValue:
                return CardanoTransactionBody.StakeDelegation(cbor: certCBOR).flatMap { .stakeDelegation($0) }
            default:
                return nil // not implemented
            }
        }
    }
}
