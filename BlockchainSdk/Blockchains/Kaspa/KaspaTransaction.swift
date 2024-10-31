//
//  KaspaTransaction.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 15.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Sodium

struct KaspaTransaction {
    let inputs: [BitcoinUnspentOutput]
    let outputs: [KaspaOutput]

    private let blake2bDigestKey = "TransactionSigningHash".data(using: .utf8)?.bytes ?? []

    var transactionHash: Data? {
        return hashTransaction(.TransactionHash)
    }

    var transactionId: Data? {
        return hashTransaction(.TransactionID)
    }

    func hashForSignatureWitness(inputIndex: Int, connectedScript: Data, prevValue: UInt64) -> Data {
        var data = Data()
        data.append(UInt16(0).data) // version
        data.append(hashPrevouts())
        data.append(hashSequence())
        data.append(hashSigOpCounts())
        data.append(Data(hexString: inputs[inputIndex].transactionHash))
        data.append(UInt32(inputs[inputIndex].outputIndex).data)
        data.append(UInt16(0).data) // script version
        data.append(UInt64(connectedScript.count).data)
        data.append(connectedScript)
        data.append(prevValue.data)
        data.append(UInt64(0).data) // sequence number
        data.append(UInt8(1).data) // sig op count
        data.append(hashOutputs())
        data.append(UInt64(0).data) // locktime
        data.append(Data(repeating: 0, count: 20)) // subnetwork id
        data.append(UInt64(0).data) // gas
        data.append(Data(repeating: 0, count: 32)) // payload hash
        data.append(UInt8(1).data) // sig op count

        let transactionSigningHashECDSA = KaspaUtils.KaspaHashType.TransactionSigningHashECDSA.data.sha256()

        var finalData = Data()
        finalData.append(transactionSigningHashECDSA)
        finalData.append(blake2bDigest(for: data))

        return finalData.sha256()
    }

    private func hashPrevouts() -> Data {
        var data = Data()
        for input in inputs {
            data.append(Data(hexString: input.transactionHash))
            data.append(UInt32(input.outputIndex).data)
        }
        return blake2bDigest(for: data)
    }

    private func hashSequence() -> Data {
        var data = Data()
        for _ in inputs {
            data.append(UInt64(0).data)
        }
        return blake2bDigest(for: data)
    }

    private func hashSigOpCounts() -> Data {
        let data = Data(repeating: UInt8(1), count: inputs.count)
        return blake2bDigest(for: data)
    }

    private func hashOutputs() -> Data {
        var data = Data()
        for output in outputs {
            data.append(output.amount.data)
            data.append(UInt16(output.scriptPublicKey.version).data)

            let scriptPublicKeyBytes = Data(hexString: output.scriptPublicKey.scriptPublicKey)
            data.append(UInt64(scriptPublicKeyBytes.count).data)
            data.append(scriptPublicKeyBytes)
        }

        return blake2bDigest(for: data)
    }

    private func blake2bDigest(for data: Data) -> Data {
        let length = 32
        // TODO: Use extension from Data+ and refactor to handle optional Data
        return Data(Sodium().genericHash.hash(message: data.bytes, key: blake2bDigestKey, outputLength: length) ?? [])
    }

    private func hashTransaction(_ hashType: KaspaUtils.KaspaHashType) -> Data? {
        func encodedInputsSigScript(for input: BitcoinUnspentOutput, type: KaspaUtils.KaspaHashType) -> Data {
            switch type {
            case .TransactionID:
                return UInt64(0).data

            case .TransactionHash:
                let script = Data(hex: input.outputScript)
                return UInt64(script.count).data + script + UInt8(0x01).data

            default:
                return Data()
            }
        }

        let encodedInputs: [Data] = inputs.map {
            [
                Data(hex: $0.transactionHash),
                UInt32($0.outputIndex).data,
                encodedInputsSigScript(for: $0, type: hashType),
                UInt64(0).data, // Sequence
            ].reduce(Data(), +)
        }

        let encodedOutputs: [Data] = outputs.map {
            let scriptPublicKeyData = Data(hex: $0.scriptPublicKey.scriptPublicKey)

            return [
                $0.amount.data,
                UInt16($0.scriptPublicKey.version & 0xffff).data,
                UInt64(scriptPublicKeyData.count).data,
                scriptPublicKeyData,
            ].reduce(Data(), +)
        }

        let data = [
            UInt16(0).data, // Version
            UInt64(encodedInputs.count).data, // Inputs count
            encodedInputs.reduce(Data(), +), // Inputs
            UInt64(encodedOutputs.count).data, // Outputs count
            encodedOutputs.reduce(Data(), +), // Outputs
            UInt64(0).data, // Locktime
            Data(repeating: 0, count: 20), // SubnetworkID
            UInt64(0).data, // Gas
            UInt64(0).data, // Payload size
        ]

        return data.reduce(Data(), +).hashBlake2b(key: hashType.data, outputLength: 32)
    }
}
