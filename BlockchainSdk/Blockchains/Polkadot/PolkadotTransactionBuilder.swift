//
//  PolkadotTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 28.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import ScaleCodec

class PolkadotTransactionBuilder {
    private let walletPublicKey: Data
    private let blockchain: Blockchain
    private let network: PolkadotNetwork
    private let runtimeVersionProvider: SubstrateRuntimeVersionProvider
    private let codec = SCALE.default

    /*
     Polkadot and Kusama indexes are taken from TrustWallet:
     https://github.com/trustwallet/wallet-core/blob/a771f38d3af112db7098730a5b0b9a1a9b65ca86/src/Polkadot/Extrinsic.cpp#L30

     Westend index is taken from the transaction made by Fearless iOS app

     This stuff can also be found in the sources. Look for `pallet_balances`.

     Polkadot:
     https://github.com/paritytech/polkadot/blob/3b68869e14f84b043aa65bd83f9fe44359e4d626/runtime/polkadot/src/lib.rs#L1341
     Kusama:
     https://github.com/paritytech/polkadot/blob/3b68869e14f84b043aa65bd83f9fe44359e4d626/runtime/kusama/src/lib.rs#L1375
     Westend:
     https://github.com/paritytech/polkadot/blob/3b68869e14f84b043aa65bd83f9fe44359e4d626/runtime/westend/src/lib.rs#L982

     For other chains use experimentally obtained values, or try running the script in the PolkaParachainMetadataParser folder
     */
    private var balanceTransferCallIndex: Data {
        switch network {
        case .polkadot, .azero, .joystream, .bittensor:
            return Data(hexString: "0x0500")
        case .kusama:
            return Data(hexString: "0x0400")
        case .westend:
            return Data(hexString: "0x0400")
        case .energyWebX:
            return Data(hexString: "0x0a07")
        }
    }

    private let extrinsicFormat: UInt8 = 0x04
    private let signedBit: UInt8 = 0x80
    private let sigTypeEd25519: UInt8 = 0x00

    init(
        blockchain: Blockchain,
        walletPublicKey: Data,
        network: PolkadotNetwork,
        runtimeVersionProvider: SubstrateRuntimeVersionProvider
    ) {
        self.walletPublicKey = walletPublicKey
        self.blockchain = blockchain
        self.network = network
        self.runtimeVersionProvider = runtimeVersionProvider
    }

    func buildForSign(amount: Amount, destination: String, meta: PolkadotBlockchainMeta) throws -> Data {
        let rawAddress = encodingRawAddress(specVersion: meta.specVersion)
        let runtimeVersion = runtimeVersionProvider.runtimeVersion(for: meta)

        var message = Data()
        message.append(try encodeCall(amount: amount, destination: destination, rawAddress: rawAddress))
        message.append(try encodeEraNonceTip(era: meta.era, nonce: meta.nonce, tip: 0))
        message.append(try encodeCheckMetadataHashExtensionModeIfNeeded(runtimeVersion: runtimeVersion))
        message.append(try codec.encode(meta.specVersion))
        message.append(try codec.encode(meta.transactionVersion))
        message.append(Data(hexString: meta.genesisHash))
        message.append(Data(hexString: meta.blockHash))
        message.append(try encodeCheckMetadataHashExtensionPayloadIfNeeded(runtimeVersion: runtimeVersion))

        return message
    }

    func buildForSend(amount: Amount, destination: String, meta: PolkadotBlockchainMeta, signature: Data) throws -> Data {
        let rawAddress = encodingRawAddress(specVersion: meta.specVersion)
        let runtimeVersion = runtimeVersionProvider.runtimeVersion(for: meta)

        let address = PolkadotAddress(publicKey: walletPublicKey, network: network)
        guard let addressBytes = address.bytes(raw: rawAddress) else {
            throw BlockchainSdkError.failedToConvertPublicKey
        }

        var transactionData = Data()
        transactionData.append(Data(extrinsicFormat | signedBit))
        transactionData.append(addressBytes)
        transactionData.append(Data(sigTypeEd25519))
        transactionData.append(signature)
        transactionData.append(try encodeEraNonceTip(era: meta.era, nonce: meta.nonce, tip: 0))
        transactionData.append(try encodeCheckMetadataHashExtensionModeIfNeeded(runtimeVersion: runtimeVersion))
        transactionData.append(try encodeCall(amount: amount, destination: destination, rawAddress: rawAddress))

        let messageLength = try messageLength(transactionData)
        transactionData = messageLength + transactionData

        return transactionData
    }

    private func encodeCall(amount: Amount, destination: String, rawAddress: Bool) throws -> Data {
        var call = Data()

        call.append(balanceTransferCallIndex)

        guard
            let address = PolkadotAddress(string: destination, network: network),
            let addressBytes = address.bytes(raw: rawAddress)
        else {
            throw BlockchainSdkError.failedToConvertPublicKey
        }
        call.append(addressBytes)

        let decimalValue = amount.value * blockchain.decimalValue
        let intValue = BigUInt((decimalValue.rounded() as NSDecimalNumber).uint64Value)
        call.append(try codec.encode(intValue, .compact))

        return call
    }

    // Use experimentally obtained values
    private func encodingRawAddress(specVersion: UInt32) -> Bool {
        switch network {
        case .polkadot:
            return specVersion < 28
        case .kusama:
            return specVersion < 2028
        case .westend, .azero, .bittensor, .energyWebX:
            return false
        case .joystream:
            // specVersion at the moment of initial implementation is '2003'
            // currently appending '00' before address bytes creates invalid transactions
            // this may change at some point in the future and new logic may look similar to polkadot and kusama cases
            return true
        }
    }

    private func encodeEraNonceTip(era: PolkadotBlockchainMeta.Era?, nonce: UInt64, tip: UInt64) throws -> Data {
        var data = Data()

        if let era = era {
            let encodedEra = encodeEra(era)
            data.append(encodedEra)
        } else {
            // TODO: This is taken from WalletCore code but it doesn't work.
            // TODO: RPC error is returned: "Transaction has a bad signature".
            data.append(try codec.encode(UInt64(0), .compact))
        }

        let nonce = try codec.encode(nonce, .compact)
        data.append(nonce)

        let tipData = try codec.encode(BigUInt(tip), .compact)
        data.append(tipData)

        return data
    }

    private func encodeEra(_ era: PolkadotBlockchainMeta.Era) -> Data {
        var calPeriod = UInt64(pow(2, ceil(log2(Double(era.period)))))
        calPeriod = min(max(calPeriod, UInt64(4)), UInt64(1) << 16)

        let phase = era.blockNumber % calPeriod
        let quantizeFactor = max(calPeriod >> UInt64(12), UInt64(1))
        let quantizedPhase = phase / quantizeFactor * quantizeFactor

        let trailingZeros = UInt64(calPeriod.trailingZeroBitCount)

        let encoded = min(15, max(1, trailingZeros - 1)) + ((quantizedPhase / quantizeFactor) << 4)
        return Data(UInt8(encoded & 0xff)) + Data(UInt8(encoded >> 8))
    }

    private func messageLength(_ message: Data) throws -> Data {
        let length = UInt64(message.count)
        let encoded = try codec.encode(length, .compact)
        return encoded
    }

    private func encodeCheckMetadataHashExtensionModeIfNeeded(runtimeVersion: SubstrateRuntimeVersion) throws -> Data {
        var data = Data()

        switch runtimeVersion {
        case .v14:
            break
        case .v15:
            // Encoding `CheckMetadataHash::Mode` for runtime extension `CheckMetadataHash`
            // `CheckMetadataHash::Mode` is actually an enum (`Mode.Disabled`/`Mode.Enabled`), but encoded as uint8
            let checkMetadataHashMode = try codec.encode(UInt8(0), .compact)
            data.append(checkMetadataHashMode)
        }

        return data
    }

    /// The payload isn't actually used (since we've disabled the `CheckMetadataHash` runtime extension anyway),
    /// but is required by Substrate Runtime v15:
    /// https://polkadot.js.org/apps/?rpc=wss%3A%2F%2Frpc.ibp.network%2Fkusama#/extrinsics/decode/0x0403008eaf04151687736326c9fea17e25fc5287613693c912909cb226aa4794f26a480700e40b5402
    private func encodeCheckMetadataHashExtensionPayloadIfNeeded(runtimeVersion: SubstrateRuntimeVersion) throws -> Data {
        var data = Data()

        switch runtimeVersion {
        case .v14:
            break
        case .v15:
            // Since we explicitly disabled `CheckMetadataHash` runtime extension (`Mode.Disabled`) on the client side -
            // no actual payload is constructed and null is encoded instead
            let checkMetadataHashPayload = try codec.encode(UInt8(0), .compact)
            data.append(checkMetadataHashPayload)
        }

        return data
    }
}
