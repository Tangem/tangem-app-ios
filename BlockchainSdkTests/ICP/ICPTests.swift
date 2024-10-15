//
//  ICPTests.swift
//  BlockchainSdkTests
//
//  Created by Dmitry Fedorov on 22.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
import WalletCore
import TangemSdk
@testable import BlockchainSdk

final class ICPTests: XCTestCase {
    private let sizeTester = TransactionSizeTesterUtility()
    
    func testTransactionBuild() throws {
        // tiny escape drive pupil flavor endless love walk gadget match filter luxury
        let privateKeyRaw = Data(hex: "e120fc1ef9d193a851926ebd937c3985dc2c4e642fb3d0832317884d5f18f3b3")
        let privateKey = WalletCore.PrivateKey(data: privateKeyRaw)!
        let publicKey = privateKey.getPublicKeySecp256k1(compressed: false)
        
        let nonce = Data(hex: "5b4210ba3969eff9b64163012d48935cf72bb86e0e444c431d28f64888af41f5")
        
        let txBuilder = ICPTransactionBuilder(
            decimalValue: Blockchain.internetComputer.decimalValue,
            publicKey: publicKey.data,
            nonce: nonce
        )
        
        let amounValueDecimal = Decimal(stringValue: "0.0001")!
        
        let amountValue = Amount(with: .internetComputer, value: amounValueDecimal)
        let feeValue = Amount(with: .internetComputer, value: .init(stringValue: "0.0001")!)

        
        let addressService = WalletCoreAddressService(blockchain: .internetComputer)
        let sourceAddress = try addressService.makeAddress(
            for: Wallet.PublicKey(seedKey: publicKey.data, derivationType: nil),
            with: .default
        ).value
        
        let transaction = Transaction(
            amount: amountValue,
            fee: Fee(feeValue),
            sourceAddress: sourceAddress,
            destinationAddress: "8fea60e397b78e3ace6f3f04fd3ba843e6a47cee5dc360fcb061be42c7fc7e2c",
            changeAddress: ""
        )
        
        let date = Date(timeIntervalSince1970: 1722489726.612402)

        let input = try txBuilder.buildForSign(transaction: transaction, date: date)
        
        let hashesToSign = input.hashes()
        
        let firstHash = try XCTUnwrap(hashesToSign[safe: 0])
        let secondHash = try XCTUnwrap(hashesToSign[safe: 1])
        
        XCTAssertEqual(firstHash.hex, "c089d9b5e8522b5b9b043746398a4f6665e063bf5a5d287d9af0316bf81d90bf")
        XCTAssertEqual(secondHash.hex, "97ea2934c5cc846828bbdc2185a64287e589cbe874ce265caa63bddd48fc4bed")
        
        hashesToSign.forEach { sizeTester.testTxSize($0) }
        
        let curve = try Curve(blockchain: .internetComputer)

        let signatures = try hashesToSign.map { digest in
            let signature = try XCTUnwrap(privateKey.sign(digest: digest, curve: curve))
            return try Secp256k1Signature(with: signature).normalize()
        }
        
        let firstSignature = try XCTUnwrap(signatures[safe: 0])
        let secondSignature = try XCTUnwrap(signatures[safe: 1])
        
        XCTAssertEqual(firstSignature.hex, "2b0084b9c1809d8e1f60afa33021deccd5fab585620c31b778bc1d9a8c6c1ac62cafc9778af4a084a0e6eacb7d0307f4baad97150dce7b3526b8b2fa09bedef7")
        XCTAssertEqual(secondSignature.hex, "777f2a225b4c8d6c6728a3910d780a44752cff45520e7e166e32fc1709eb74f9694b34883e7e84ec3c1ae239269598f5a072dd0c46336359b442fc0abfe8a6bf")

        // https://dashboard.internetcomputer.org/transaction/9d6512c44864f259ce67035487f3c60a8ba212d438aca9697ae77da45fce887d
        let signedTransaction = try txBuilder.buildForSend(signedHashes: signatures, input: input)
        
        XCTAssertEqual(signedTransaction.callEnvelope.hex, "d9d9f7a367636f6e74656e74a76c726571756573745f747970656463616c6c6673656e646572581d43fde74164b1c767ae0adc532af1ceefb0c7acbe356e6f3f3c11040c02656e6f6e636558205b4210ba3969eff9b64163012d48935cf72bb86e0e444c431d28f64888af41f56e696e67726573735f6578706972791b17e7837f9d1b4f006b6d6574686f645f6e616d65687472616e736665726b63616e69737465725f69644a000000000000000201016361726758a04449444c056d7b6c01e0a9b302786e006c01d6f68e8001786c06fbca0100c6fcb60201ba89e5c20478a2de94eb060282f3f3910c03d8a38ca80d010104208fea60e397b78e3ace6f3f04fd3ba843e6a47cee5dc360fcb061be42c7fc7e2c1027000000000000000000000000000001200000000000000000000000000000000000000000000000000000000000000000006c7d974783e71710270000000000006d73656e6465725f7075626b657958583056301006072a8648ce3d020106052b8104000a0342000474d0f81f42ddfe34114d533e95e6ae5fe6ea271c96f1fa505199fdc365ae9720dc4704e6b8905cb97f60520640dc495eec9a37902b881455aefe82fbc36f48c76a73656e6465725f73696758402b0084b9c1809d8e1f60afa33021deccd5fab585620c31b778bc1d9a8c6c1ac62cafc9778af4a084a0e6eacb7d0307f4baad97150dce7b3526b8b2fa09bedef7")
        XCTAssertEqual(signedTransaction.readStateEnvelope.hex, "d9d9f7a367636f6e74656e74a56c726571756573745f747970656a726561645f73746174656673656e646572581d43fde74164b1c767ae0adc532af1ceefb0c7acbe356e6f3f3c11040c02656e6f6e636558205b4210ba3969eff9b64163012d48935cf72bb86e0e444c431d28f64888af41f56e696e67726573735f6578706972791b17e7837f9d1b4f0065706174687385814474696d65834e726571756573745f7374617475735820fcf4a9d4ba17b88b70b536739837bf3a5f82464e8ca7c3654c191186977733fc46737461747573834e726571756573745f7374617475735820fcf4a9d4ba17b88b70b536739837bf3a5f82464e8ca7c3654c191186977733fc457265706c79834e726571756573745f7374617475735820fcf4a9d4ba17b88b70b536739837bf3a5f82464e8ca7c3654c191186977733fc4b72656a6563745f636f6465834e726571756573745f7374617475735820fcf4a9d4ba17b88b70b536739837bf3a5f82464e8ca7c3654c191186977733fc4e72656a6563745f6d6573736167656d73656e6465725f7075626b657958583056301006072a8648ce3d020106052b8104000a0342000474d0f81f42ddfe34114d533e95e6ae5fe6ea271c96f1fa505199fdc365ae9720dc4704e6b8905cb97f60520640dc495eec9a37902b881455aefe82fbc36f48c76a73656e6465725f7369675840777f2a225b4c8d6c6728a3910d780a44752cff45520e7e166e32fc1709eb74f9694b34883e7e84ec3c1ae239269598f5a072dd0c46336359b442fc0abfe8a6bf")
    }
}
