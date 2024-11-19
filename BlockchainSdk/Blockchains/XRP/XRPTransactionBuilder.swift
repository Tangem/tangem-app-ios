//
//  XRPTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 10.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

/// XRP transactions decoder https://fluxw42.github.io/ripple-tx-decoder/
class XRPTransactionBuilder {
    var account: String?
    var sequence: Int?
    let walletPublicKey: Data
    let curve: EllipticCurve

    internal init(walletPublicKey: Data, curve: EllipticCurve) throws {
        var key: Data
        switch curve {
        case .secp256k1:
            key = try Secp256k1Key(with: walletPublicKey).compress()
        case .ed25519, .ed25519_slip0010:
            key = [UInt8(0xED)] + walletPublicKey
        default:
            fatalError("unsupported curve")
        }
        self.walletPublicKey = key
        self.curve = curve
    }

    func buildForSign(transaction: Transaction) throws -> (XRPTransaction, Data)? {
        guard let tx = try buildTransaction(from: transaction) else {
            return nil
        }

        let dataToSign = tx.dataToSign(publicKey: walletPublicKey.hexString)
        switch curve {
        case .ed25519, .ed25519_slip0010:
            return (tx, dataToSign)
        case .secp256k1:
            return (tx, dataToSign.sha512Half())
        default:
            fatalError("unsupported curve")
        }
    }

    func buildForSend(transaction: XRPTransaction, signature: Data) throws -> String {
        var sig: Data
        switch curve {
        case .ed25519, .ed25519_slip0010:
            sig = signature
        case .secp256k1:
            sig = try Secp256k1Signature(with: signature).serializeDer()
        default:
            fatalError("unsupported curve")
        }

        let signedTx = try transaction.sign(signature: sig.toBytes)
        let blob = signedTx.getBlob()
        return blob
    }

    private func buildTransaction(from transaction: Transaction) throws -> XRPTransaction? {
        guard let account = account, let sequence = sequence else {
            return nil
        }

        let amountDrops = (transaction.amount.value * Decimal(1000000)).rounded(blockchain: .xrp(curve: curve))
        let feeDrops = (transaction.fee.amount.value * Decimal(1000000)).rounded(blockchain: .xrp(curve: curve))

        let decodedXAddress = try? XRPAddress.decodeXAddress(xAddress: transaction.destinationAddress)
        let destination = decodedXAddress?.rAddress ?? transaction.destinationAddress

        let decodedTag = decodedXAddress?.tag
        let explicitTag = (transaction.params as? XRPTransactionParams)?.destinationTag

        let destinationTag: UInt32? = try {
            switch (decodedTag, explicitTag) {
            case (.some(let tag), .none):
                return tag
            case (.none, .some(let tag)):
                return tag
            case (.some(let tag1), .some(let tag2)):
                if tag1 != tag2 {
                    throw XRPError.distinctTagsFound
                }
                return tag1
            case (.none, .none): return nil
            }
        }()

        // dictionary containing partial transaction fields
        var fields: [String: Any] = [
            "Account": account,
            "TransactionType": "Payment",
            "Destination": destination,
            "Amount": "\(amountDrops)",
            // "Flags" : UInt64(2147483648),
            "Fee": "\(feeDrops)",
            "Sequence": sequence,
        ]

        if destinationTag != nil {
            fields["DestinationTag"] = destinationTag
        }

        // create the transaction from dictionary
        return XRPTransaction(fields: fields)
    }
}
