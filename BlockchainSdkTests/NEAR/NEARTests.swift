//
//  NEARTests.swift
//  BlockchainSdkTests
//
//  Created by Andrey Fedorov on 28.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
import WalletCore

@testable import BlockchainSdk

final class NEARTests: XCTestCase {
    private let blockchain: BlockchainSdk.Blockchain = .near(curve: .ed25519_slip0010, testnet: false)
    private var transactionBuilder: NEARTransactionBuilder!
    private var sizeTester: TransactionSizeTesterUtility!

    override func setUp() {
        transactionBuilder = .init()
        sizeTester = .init()
    }

    // Using example values from https://nomicon.io/DataStructures/Account#examples
    func testAddressUtilImplicitAccountsDetection() {
        XCTAssertTrue(NEARAddressUtil.isImplicitAccount(accountId: "f69cd39f654845e2059899a888681187f2cda95f29256329aea1700f50f8ae86"))
        XCTAssertTrue(NEARAddressUtil.isImplicitAccount(accountId: "75149e81ac9ea0bcb6f00faee922f71a11271f6cbc55bac97753603504d7bf27"))
        XCTAssertTrue(NEARAddressUtil.isImplicitAccount(accountId: "64acf5e86c840024032d7e75ec569a4d304443e250b197d5a0246d2d49afc8e1"))
        XCTAssertTrue(NEARAddressUtil.isImplicitAccount(accountId: "84a3fe2fc0e585d802cfa160807d1bf8ca5f949cf8d04d128bf984c50aabab7b"))
        XCTAssertTrue(NEARAddressUtil.isImplicitAccount(accountId: "d85d322043d87cc475d3523d6fb0c3df903d3830e5d4d5027ffe565e7b8652bb"))

        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "f69cd39f654845e2059899a88868.1187f2cda95f29256329aea1700f50f8ae8"))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "something.near"))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: ""))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "6f8a1e9b0c2d3f4a5b7e8d9a1c32ed5f67b8cd0e1f23b4c5d6e7f88023a"))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "9a4b6c1e2d8f3a5b7e8d9a1c3b2e4d5f6a7b8c9d0e1f2a3b4c5d6e7f8a4b6c1e2d8f3"))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "ctiud11caxsb2tw7dmfcrhfw9ah15ltkydrjfblst32986pekmb3dsvyrmyym6qn"))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "ok"))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "bowen"))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "ek-2"))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "ek.near"))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "com"))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "google.com"))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "bowen.google.com"))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "near"))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "illia.cheap-accounts.near"))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "max_99.near"))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "100"))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "near2019"))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "over.9000"))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "a.bro"))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "bro.a"))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "not ok"))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "a"))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "100-"))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "bo__wen"))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "_illia"))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: ".near"))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "near."))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "a..near"))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "$$$"))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "WAT"))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "me@google.com"))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "system"))
        XCTAssertFalse(NEARAddressUtil.isImplicitAccount(accountId: "abcdefghijklmnopqrstuvwxyz.abcdefghijklmnopqrstuvwxyz.abcdefghijklmnopqrstuvwxyz"))
    }

    // Using example values from https://nomicon.io/DataStructures/Account#examples
    func testAddressUtilNamedAccountValidation() {
        XCTAssertTrue(NEARAddressUtil.isValidNamedAccount(accountId: "f69cd39f654845e2059899a888681187f2cda95f29256329aea1700f50f8ae86"))
        XCTAssertTrue(NEARAddressUtil.isValidNamedAccount(accountId: "f69cd39f654845e2059899a88868.1187f2cda95f29256329aea1700f50f8ae8"))
        XCTAssertTrue(NEARAddressUtil.isValidNamedAccount(accountId: "something.near"))
        XCTAssertTrue(NEARAddressUtil.isValidNamedAccount(accountId: "6f8a1e9b0c2d3f4a5b7e8d9a1c32ed5f67b8cd0e1f23b4c5d6e7f88023a"))
        XCTAssertTrue(NEARAddressUtil.isValidNamedAccount(accountId: "ctiud11caxsb2tw7dmfcrhfw9ah15ltkydrjfblst32986pekmb3dsvyrmyym6qn"))
        XCTAssertTrue(NEARAddressUtil.isValidNamedAccount(accountId: "ok"))
        XCTAssertTrue(NEARAddressUtil.isValidNamedAccount(accountId: "bowen"))
        XCTAssertTrue(NEARAddressUtil.isValidNamedAccount(accountId: "ek-2"))
        XCTAssertTrue(NEARAddressUtil.isValidNamedAccount(accountId: "ek.near"))
        XCTAssertTrue(NEARAddressUtil.isValidNamedAccount(accountId: "com"))
        XCTAssertTrue(NEARAddressUtil.isValidNamedAccount(accountId: "google.com"))
        XCTAssertTrue(NEARAddressUtil.isValidNamedAccount(accountId: "bowen.google.com"))
        XCTAssertTrue(NEARAddressUtil.isValidNamedAccount(accountId: "near"))
        XCTAssertTrue(NEARAddressUtil.isValidNamedAccount(accountId: "illia.cheap-accounts.near"))
        XCTAssertTrue(NEARAddressUtil.isValidNamedAccount(accountId: "max_99.near"))
        XCTAssertTrue(NEARAddressUtil.isValidNamedAccount(accountId: "100"))
        XCTAssertTrue(NEARAddressUtil.isValidNamedAccount(accountId: "near2019"))
        XCTAssertTrue(NEARAddressUtil.isValidNamedAccount(accountId: "over.9000"))
        XCTAssertTrue(NEARAddressUtil.isValidNamedAccount(accountId: "a.bro"))
        XCTAssertTrue(NEARAddressUtil.isValidNamedAccount(accountId: "bro.a"))

        XCTAssertFalse(NEARAddressUtil.isValidNamedAccount(accountId: ""))
        XCTAssertFalse(NEARAddressUtil.isValidNamedAccount(accountId: "9a4b6c1e2d8f3a5b7e8d9a1c3b2e4d5f6a7b8c9d0e1f2a3b4c5d6e7f8a4b6c1e2d8f3"))
        XCTAssertFalse(NEARAddressUtil.isValidNamedAccount(accountId: "not ok"))
        XCTAssertFalse(NEARAddressUtil.isValidNamedAccount(accountId: "a"))
        XCTAssertFalse(NEARAddressUtil.isValidNamedAccount(accountId: "100-"))
        XCTAssertFalse(NEARAddressUtil.isValidNamedAccount(accountId: "bo__wen"))
        XCTAssertFalse(NEARAddressUtil.isValidNamedAccount(accountId: "_illia"))
        XCTAssertFalse(NEARAddressUtil.isValidNamedAccount(accountId: ".near"))
        XCTAssertFalse(NEARAddressUtil.isValidNamedAccount(accountId: "near."))
        XCTAssertFalse(NEARAddressUtil.isValidNamedAccount(accountId: "a..near"))
        XCTAssertFalse(NEARAddressUtil.isValidNamedAccount(accountId: "$$$"))
        XCTAssertFalse(NEARAddressUtil.isValidNamedAccount(accountId: "WAT"))
        XCTAssertFalse(NEARAddressUtil.isValidNamedAccount(accountId: "me@google.com"))
        XCTAssertFalse(NEARAddressUtil.isValidNamedAccount(accountId: "system"))
        XCTAssertFalse(NEARAddressUtil.isValidNamedAccount(accountId: "abcdefghijklmnopqrstuvwxyz.abcdefghijklmnopqrstuvwxyz.abcdefghijklmnopqrstuvwxyz"))
    }

    // NEAR transfer transaction https://testnet.nearblocks.io/txns/Cr3QyJoFNtQvFTfc45WDTM4GvLxQtFigSjP7wcRrwiwW
    // Made using NEAR JS API, see https://github.com/deprecated-near-examples/transaction-examples for examples
    func testSigningTransaction() throws {
        // Private key for the "tiny escape drive pupil flavor endless love walk gadget match filter luxury" mnemonic
        let privateKeyRawRepresentation = "4z9uzXnZHE6huxMbnV7egjpvQk6ov7eji3FM12buV8DDtkARhiDqiCoDxSa3VpBMKYzzjmJcVXXyw8qhYgTs6MfH"
            .base58DecodedData[0..<32]
        let privateKey = try XCTUnwrap(PrivateKey(data: privateKeyRawRepresentation))

        let publicKeyRawRepresentation = privateKey.getPublicKey(coinType: try XCTUnwrap(CoinType(blockchain))).data
        let publicKey = Wallet.PublicKey(seedKey: publicKeyRawRepresentation, derivationType: nil)

        let sourceAddress = try makeAddress(for: publicKey)
        let expectedSourceAddress = "b5cf12d432ee87dbc664e2700eeef72b3e814879b978bb9491e5796a63e85ee4"

        XCTAssertEqual(sourceAddress, expectedSourceAddress)

        let destinationAddress = "jhj909.testnet"
        let value = try XCTUnwrap(Decimal(string: "3.891"))
        let amount = Amount(with: blockchain, value: value)
        let fee = Fee(.zeroCoin(for: blockchain))  // Not used in the transaction, therefore a dummy value is used

        let transactionParams = NEARTransactionParams(
            publicKey: publicKey,
            currentNonce: 143936156000003,
            recentBlockHash: "5M4mFZLMT6Qe9fNpXBipmYQ6u2gk4kkzXgd1ebt1zW23"
        )

        let transaction = Transaction(
            amount: amount,
            fee: fee,
            sourceAddress: sourceAddress,
            destinationAddress: destinationAddress,
            changeAddress: sourceAddress
        ).then { $0.params = transactionParams }

        let transactionHash = try transactionBuilder.buildForSign(transaction: transaction)

        sizeTester.testTxSize(transactionHash)

        let curve = try Curve(blockchain: blockchain)
        let transactionSignature = try XCTUnwrap(privateKey.sign(digest: transactionHash, curve: curve))

        let signedTransaction = try transactionBuilder.buildForSend(transaction: transaction, signature: transactionSignature)
        let base64EncodedTransaction = signedTransaction.base64EncodedString()

        let expectedBase64EncodedTransaction = """
QAAAAGI1Y2YxMmQ0MzJlZTg3ZGJjNjY0ZTI3MDBlZWVmNzJiM2U4MTQ4NzliOTc4YmI5NDkxZTU3OTZhNjNlODVlZTQAtc8S1DL\
uh9vGZOJwDu73Kz6BSHm5eLuUkeV5amPoXuQE33K/6IIAAA4AAABqaGo5MDkudGVzdG5ldECSnmDjrfGWWZfgb+lcQvfOE8jy8/\
OdCy4+7VFwsBwYAQAAAAMAAOC5djZciPM3AwAAAAAAAEvPwwDL+M+IGs7G69be8CXlnKwbPp6NTpoWoAHukon9gCjyKhBpfWQwU\
mvfgIZi953LT5fMzOlUEX6l9MlpzwM=
"""

        XCTAssertEqual(base64EncodedTransaction, expectedBase64EncodedTransaction)
    }

    private func makeAddress(for publicKey: BlockchainSdk.Wallet.PublicKey) throws -> String {
        let addressServiceFactory = AddressServiceFactory(blockchain: blockchain)
        let addressService = addressServiceFactory.makeAddressService()

        return try addressService.makeAddress(for: publicKey, with: .default).value
    }
}
