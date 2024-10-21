//
//  TezosTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 20.10.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Sodium
import stellarsdk
import TangemSdk

class TezosTransactionBuilder {
    var counter: Int? = nil
    var isPublicKeyRevealed: Bool? = nil
    
    private let walletPublicKey: Data
    private let curve: EllipticCurve
    
    internal init(walletPublicKey: Data, curve: EllipticCurve) throws {
        switch curve {
        case .ed25519, .ed25519_slip0010:
            self.walletPublicKey = walletPublicKey
        case .secp256k1:
            self.walletPublicKey = try Secp256k1Key(with: walletPublicKey).compress()
        case .secp256r1:
            fatalError("Not implemented")
        default:
            fatalError("unsupported curve")
        }
        self.curve = curve
    }
    
    func buildToSign(forgedContents: String) -> Data? {
        let message = TezosPrefix.Watermark.genericOperation + Data(hex: forgedContents)
        // TODO: Use extension from Data+
        return Sodium().genericHash.hash(message: message.bytes, outputLength: 32).map { Data($0) }
    }

    func buildToSend(signature: Data, forgedContents: String) -> String {
        return forgedContents + signature.hexString
    }

    func buildContents(transaction: Transaction) -> [TezosOperationContent]? {
        guard var counter = self.counter, let isPublicKeyRevealed = self.isPublicKeyRevealed else {
            return nil
        }
        
        var contents = [TezosOperationContent]()
        contents.reserveCapacity(isPublicKeyRevealed ? 1 : 2)

        if !isPublicKeyRevealed {
            counter += 1
            let revealOp = TezosOperationContent(
                kind: "reveal",
                source: transaction.sourceAddress,
                fee: TezosFee.reveal.mutezValue,
                counter: counter.description,
                gasLimit: "10000",
                storageLimit:  "0",
                publicKey: encodePublicKey(), //checkit
                destination: nil,
                amount: nil)
            
            contents.append(revealOp)
        }

        counter += 1
        let transactionOp = TezosOperationContent(
            kind: "transaction",
            source: transaction.sourceAddress,
            fee: TezosFee.transaction.mutezValue,
            counter: counter.description,
            gasLimit:  "10600",
            storageLimit:  "300", // set it to 0?
            publicKey: nil,
            destination: transaction.destinationAddress,
            amount: (transaction.amount.value * Blockchain.tezos(curve: .ed25519).decimalValue).description)
        
        contents.append(transactionOp)
        return contents
    }
    
    func forgeContents(headerHash: String, contents: [TezosOperationContent]) throws -> String {
        var forged: String = ""
        
        guard let branchHex = headerHash.base58CheckDecodedData?.hexString
                .dropFirst(TezosPrefix.branch.count) else {
            throw TezosError.headerHashDecodeFailed
        }
        
        forged += branchHex
        
        for content in contents {
            guard let kind = TezosPrefix.TransactionKind(rawValue: content.kind) else {
                throw TezosError.operationKindDecodeFailed
            }
            
            forged += kind.encodedPrefix
            
            forged += try content.source.encodePublicKeyHash()
            forged += try content.fee.encodeInt()
            forged += try content.counter.encodeInt()
            forged += try content.gasLimit.encodeInt()
            forged += try content.storageLimit.encodeInt()
            
            // reveal operation only
            try content.publicKey.map {
                let encoded = try $0.encodePublicKey()
                forged += encoded
            }
            
            // transaction operation only
            try content.amount.map {
                let encoded = try $0.encodeInt()
                forged += encoded
            }
            
            try content.destination.map {
                let encoded = try $0.encodeAddress()
                
                forged += encoded
                // parameters for transaction operation, we don't use them yet
                forged += "00"
            }
        }
        
        return forged
    }
    
    private func encodePublicKey() -> String {
        let publicPrefix = TezosPrefix.publicPrefix(for: curve)
        let prefixedPubKey = publicPrefix + walletPublicKey
        
        let checksum = prefixedPubKey.sha256().sha256().prefix(4)
        let prefixedHashWithChecksum = prefixedPubKey + checksum

        return Base58.encode(prefixedHashWithChecksum)
    }
}


fileprivate extension String {
    // Zarith encoding
    func encodeInt() throws -> String {
        guard var nn = UInt64(self) else {
            throw WalletError.failedToBuildTx
        }
        
        var result = ""
        
        while (true) {
            if (nn < 128) {
                if (nn < 16) {
                    result += "0"
                }
                result += String(nn, radix: 16)
                break
            } else {
                var b = nn % 128
                nn -= b
                nn /= 128
                b += 128
                result += String(b, radix: 16)
            }
        }
        return result
    }
    
    func encodeAddress() throws -> String {
        guard let addressHex = self.base58CheckDecodedData?.hexString else {
            throw TezosError.encodeAddressFailed
        }
        
        let rawPrefix = addressHex[addressHex.startIndex...addressHex.index(addressHex.startIndex, offsetBy: 5)]
        
        guard let addressPrefix = TezosPrefix.Address(rawValue: String(rawPrefix)) else {
            throw TezosError.addressPrefixParseFailed
        }
        
        switch addressPrefix {
        case .tz1, .tz2, .tz3:
            let encodedPublicKeyHash = try encodePublicKeyHash()
            return "00" + encodedPublicKeyHash
        case .kt1:
            return "01" + addressHex.dropFirst(rawPrefix.count) + "00"
        }
    }
    
    func encodePublicKey() throws -> String {
        guard let keyHex = self.base58CheckDecodedData?.hexString else {
            throw TezosError.encodePublicKeyFailed
        }
        
        let rawPrefix = keyHex[keyHex.startIndex...keyHex.index(keyHex.startIndex, offsetBy: 7)]
        
        guard let keyPrefix = TezosPrefix.PublicKey(rawValue: String(rawPrefix)) else {
            throw TezosError.publicKeyPrefixParseFailed
        }
        
        return keyPrefix.encodedPrefix + keyHex.dropFirst(rawPrefix.count)
    }
    
    func encodePublicKeyHash() throws -> String {
        guard let addressHex = self.base58CheckDecodedData?.hexString else {
            throw TezosError.encodePublicKeyHashFailed
        }
        
        let rawPrefix = addressHex[addressHex.startIndex...addressHex.index(addressHex.startIndex, offsetBy: 5)]
        
        guard let addressPrefix = TezosPrefix.Address(rawValue: String(rawPrefix)) else {
            throw TezosError.addressPrefixParseFailed
        }
                
        return addressPrefix.encodedPrefix + addressHex.dropFirst(rawPrefix.count)
    }
}


enum TezosError: String, Error, LocalizedError {
    case encodeAddressFailed
    case encodePublicKeyFailed
    case encodePublicKeyHashFailed
    case addressPrefixParseFailed
    case publicKeyPrefixParseFailed
    case headerHashDecodeFailed
    case operationKindDecodeFailed
    
    var errorDescription: String? {
        return self.rawValue
    }
}
