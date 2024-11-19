//
//  PolkadotTests.swift
//  BlockchainSdkTests
//
//  Created by Andrey Chukavin on 04.02.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import XCTest
import Combine
import CryptoKit
import TangemSdk
@testable import BlockchainSdk

class PolkadotTests: XCTestCase {
    // Taken from trust wallet, `SignerTests.cpp`
    private let sizeTester = TransactionSizeTesterUtility()

    // MARK: - Polkadot substrate runtime v14

    func testTransaction9fd062Ed25519RuntimeV14() throws {
        try testTransaction9fd062RuntimeV14(curve: .ed25519)
    }

    func testTransaction9fd062Ed25519Slip0010RuntimeV14() throws {
        try testTransaction9fd062RuntimeV14(curve: .ed25519_slip0010)
    }

    private func testTransaction9fd062RuntimeV14(curve: EllipticCurve) throws {
        let privateKey = Data(hexString: "0x70a794d4f1019c3ce002f33062f45029c4f930a56b3d20ec477f7668c6bbc37f")
        let publicKey = try XCTUnwrap(Curve25519.Signing.PrivateKey(rawRepresentation: privateKey).publicKey.rawRepresentation)
        let blockchain: Blockchain = .polkadot(curve: curve, testnet: false)
        let network = try XCTUnwrap(PolkadotNetwork(blockchain: blockchain))
        let runtimeVersionProvider = SubstrateRuntimeVersionProvider(network: network)

        let txBuilder = PolkadotTransactionBuilder(
            blockchain: blockchain,
            walletPublicKey: publicKey,
            network: network,
            runtimeVersionProvider: runtimeVersionProvider
        )

        let value = try XCTUnwrap(Decimal(stringValue: "0.2"))
        let amount = Amount(with: blockchain, value: value)
        let destination = "13ZLCqJNPsRZYEbwjtZZFpWt9GyFzg5WahXCVWKpWdUJqrQ5"
        let meta = PolkadotBlockchainMeta(
            specVersion: 26,
            transactionVersion: 5,
            genesisHash: "91b171bb158e2d3848fa23a9f1c25182fb8e20313b2c1eb49219da7a70ce90c3",
            blockHash: "0x5d2143bb808626d63ad7e1cda70fa8697059d670a992e82cd440fbb95ea40351",
            nonce: 3,
            era: .init(blockNumber: 3541050, period: 64)
        )

        let runtimeVersion = runtimeVersionProvider.runtimeVersion(for: meta)
        XCTAssertEqual(runtimeVersion, .v14)

        let preImage = try XCTUnwrap(txBuilder.buildForSign(amount: amount, destination: destination, meta: meta))
        sizeTester.testTxSize(preImage)

        let signature = try XCTUnwrap(signEd25519(message: preImage, privateKey: privateKey))
        let image = try XCTUnwrap(txBuilder.buildForSend(amount: amount, destination: destination, meta: meta, signature: signature))

        let expectedPreImage = Data(
            hexString: """
            0x05007120f76076bcb0efdf94c7219e116899d0163ea61cb428183d71324eb33b2bce0300943577a5030c001\
            a0000000500000091b171bb158e2d3848fa23a9f1c25182fb8e20313b2c1eb49219da7a70ce90c35d2143bb80\
            8626d63ad7e1cda70fa8697059d670a992e82cd440fbb95ea40351
            """
        )
        let expectedImage = Data(
            hexString: """
            0x3502849dca538b7a925b8ea979cc546464a3c5f81d2398a3a272f6f93bdf4803f2f7830073e59cef381aedf56d7af076bafff9857\
            ffc1e3bd7d1d7484176ff5b58b73f1211a518e1ed1fd2ea201bd31869c0798bba4ffe753998c409d098b65d25dff801a5030c000500\
            7120f76076bcb0efdf94c7219e116899d0163ea61cb428183d71324eb33b2bce0300943577
            """
        )
        XCTAssertEqual(preImage, expectedPreImage)

        let (imageWithoutSignature, expectedImageWithoutSignature) = try removeSignature(
            image: image,
            expectedImage: expectedImage,
            signature: signature
        )
        XCTAssertEqual(imageWithoutSignature, expectedImageWithoutSignature)
    }

    func testTransactionEd25519RuntimeV14() throws {
        try testTransactionRuntimeV14(curve: .ed25519)
    }

    func testTransactionEd25519Slip0010RuntimeV14() throws {
        try testTransactionRuntimeV14(curve: .ed25519_slip0010)
    }

    private func testTransactionRuntimeV14(curve: EllipticCurve) throws {
        let toAddress = Data(hexString: "0x8eaf04151687736326c9fea17e25fc5287613693c912909cb226aa4794f26a48")
        let privateKey = Data(hexString: "0xabf8e5bdbe30c65656c0a3cbd181ff8a56294a69dfedd27982aace4a76909115")
        let publicKey = try XCTUnwrap(Curve25519.Signing.PrivateKey(rawRepresentation: privateKey).publicKey.rawRepresentation)
        let blockchain: Blockchain = .polkadot(curve: curve, testnet: false)
        let network = try XCTUnwrap(PolkadotNetwork(blockchain: blockchain))
        let runtimeVersionProvider = SubstrateRuntimeVersionProvider(network: network)

        let txBuilder = PolkadotTransactionBuilder(
            blockchain: blockchain,
            walletPublicKey: publicKey,
            network: network,
            runtimeVersionProvider: runtimeVersionProvider
        )

        let amount = Amount(with: blockchain, value: 12345 / blockchain.decimalValue)
        let destination = try XCTUnwrap(PolkadotAddressService(network: network).makeAddress(from: toAddress)).value
        let meta = PolkadotBlockchainMeta(
            specVersion: 17,
            transactionVersion: 3,
            genesisHash: "91b171bb158e2d3848fa23a9f1c25182fb8e20313b2c1eb49219da7a70ce90c3",
            blockHash: "0x343a3f4258fd92f5ca6ca5abdf473d86a78b0bcd0dc09c568ca594245cc8c642",
            nonce: 0,
            era: .init(blockNumber: 927699, period: 8)
        )

        let runtimeVersion = runtimeVersionProvider.runtimeVersion(for: meta)
        XCTAssertEqual(runtimeVersion, .v14)

        let preImage = try XCTUnwrap(txBuilder.buildForSign(amount: amount, destination: destination, meta: meta))
        sizeTester.testTxSize(preImage)

        let signature = try XCTUnwrap(signEd25519(message: preImage, privateKey: privateKey))
        let image = try XCTUnwrap(txBuilder.buildForSend(amount: amount, destination: destination, meta: meta, signature: signature))

        let expectedPreImage = Data(
            hexString: """
            0x05008eaf04151687736326c9fea17e25fc5287613693c912909cb226aa4794f26a48e5c032000000110000000300000091b17\
            1bb158e2d3848fa23a9f1c25182fb8e20313b2c1eb49219da7a70ce90c3343a3f4258fd92f5ca6ca5abdf473d86a78b0bcd0d\
            c09c568ca594245cc8c642
            """
        )
        let expectedImage = Data(
            hexString: """
            0x29028488dc3417d5058ec4b4503e0c12ea1a0a89be200fe98922423d4334014fa6b0ee003d91a06263956d8ce3ce5c55455ba\
            efff299d9cb2bb3f76866b6828ee4083770b6c03b05d7b6eb510ac78d047002c1fe5c6ee4b37c9c5a8b09ea07677f12e50d32000\
            00005008eaf04151687736326c9fea17e25fc5287613693c912909cb226aa4794f26a48e5c0
            """
        )
        XCTAssertEqual(preImage, expectedPreImage)

        let (imageWithoutSignature, expectedImageWithoutSignature) = try removeSignature(
            image: image,
            expectedImage: expectedImage,
            signature: signature
        )
        XCTAssertEqual(imageWithoutSignature, expectedImageWithoutSignature)
    }

    func testTransaction72dd5bEd25519RuntimeV14() throws {
        try testTransaction72dd5bRuntimeV14(curve: .ed25519)
    }

    func testTransaction72dd5bEd25519Slip0010RuntimeV14() throws {
        try testTransaction72dd5bRuntimeV14(curve: .ed25519_slip0010)
    }

    private func testTransaction72dd5bRuntimeV14(curve: EllipticCurve) throws {
        let privateKey = Data(hexString: "0x37932b086586a6675e66e562fe68bd3eeea4177d066619c602fe3efc290ada62")
        let publicKey = try XCTUnwrap(Curve25519.Signing.PrivateKey(rawRepresentation: privateKey).publicKey.rawRepresentation)
        let blockchain: Blockchain = .polkadot(curve: curve, testnet: false)
        let network = try XCTUnwrap(PolkadotNetwork(blockchain: blockchain))
        let runtimeVersionProvider = SubstrateRuntimeVersionProvider(network: network)

        let txBuilder = PolkadotTransactionBuilder(
            blockchain: blockchain,
            walletPublicKey: publicKey,
            network: network,
            runtimeVersionProvider: runtimeVersionProvider
        )

        let amount = Amount(with: blockchain, value: 1)
        let destination = "13ZLCqJNPsRZYEbwjtZZFpWt9GyFzg5WahXCVWKpWdUJqrQ5"
        let meta = PolkadotBlockchainMeta(
            specVersion: 28,
            transactionVersion: 6,
            genesisHash: "91b171bb158e2d3848fa23a9f1c25182fb8e20313b2c1eb49219da7a70ce90c3",
            blockHash: "7d5fa17b70251d0806f26156b1b698dfd09e040642fa092595ce0a78e9e84fcd",
            nonce: 1,
            era: .init(blockNumber: 3910736, period: 64)
        )

        let runtimeVersion = runtimeVersionProvider.runtimeVersion(for: meta)
        XCTAssertEqual(runtimeVersion, .v14)

        let preImage = try XCTUnwrap(txBuilder.buildForSign(amount: amount, destination: destination, meta: meta))
        sizeTester.testTxSize(preImage)

        let signature = try XCTUnwrap(signEd25519(message: preImage, privateKey: privateKey))
        let image = try XCTUnwrap(txBuilder.buildForSend(amount: amount, destination: destination, meta: meta, signature: signature))

        let expectedPreImage = Data(
            hexString: """
            0500007120f76076bcb0efdf94c7219e116899d0163ea61cb428183d71324eb33b2bce0700e40b5402050104001c00000006000000\
            91b171bb158e2d3848fa23a9f1c25182fb8e20313b2c1eb49219da7a70ce90c37d5fa17b70251d0806f26156b1b698dfd09e040642\
            fa092595ce0a78e9e84fcd
            """
        )
        let expectedImage = Data(
            hexString: """
            410284008d96660f14babe708b5e61853c9f5929bc90dd9874485bf4d6dc32d3e6f22eaa0038ec4973ab9773dfcbf170b8d27d36d8\
            9b85c3145e038d68914de83cf1f7aca24af64c55ec51ba9f45c5a4d74a9917dee380e9171108921c3e5546e05be152060501040005\
            00007120f76076bcb0efdf94c7219e116899d0163ea61cb428183d71324eb33b2bce0700e40b5402
            """
        )
        XCTAssertEqual(preImage, expectedPreImage)

        let (imageWithoutSignature, expectedImageWithoutSignature) = try removeSignature(
            image: image,
            expectedImage: expectedImage,
            signature: signature
        )
        XCTAssertEqual(imageWithoutSignature, expectedImageWithoutSignature)
    }

    // MARK: - Polkadot substrate runtime v15

    func testTransactionEd25519RuntimeV15() throws {
        try testTransactionRuntimeV15(curve: .ed25519)
    }

    func testTransactionEd25519Slip0010RuntimeV15() throws {
        try testTransactionRuntimeV15(curve: .ed25519_slip0010)
    }

    // https://westend.subscan.io/extrinsic/21410256-2
    private func testTransactionRuntimeV15(curve: EllipticCurve) throws {
        let privateKey = Data(hexString: "0x360B498C9157BAA460790AB4AC03D74166C6ED993A1D3C871E30AF3D86150F49")
        let publicKey = try XCTUnwrap(Curve25519.Signing.PrivateKey(rawRepresentation: privateKey).publicKey.rawRepresentation)
        let blockchain: Blockchain = .polkadot(curve: curve, testnet: true)
        let network = try XCTUnwrap(PolkadotNetwork(blockchain: blockchain))
        let runtimeVersionProvider = SubstrateRuntimeVersionProvider(network: network)

        let txBuilder = PolkadotTransactionBuilder(
            blockchain: blockchain,
            walletPublicKey: publicKey,
            network: network,
            runtimeVersionProvider: runtimeVersionProvider
        )

        let value = try XCTUnwrap(Decimal(stringValue: "0.355728311783"))
        let amount = Amount(with: blockchain, value: value)
        let destination = "5C8ssaTbSTxDtTRf97rJ8cDrLzeQDULHHEnq4ngjjRMMoQRw"
        let meta = PolkadotBlockchainMeta(
            specVersion: 1013000,
            transactionVersion: 26,
            genesisHash: "0xe143f23803ac50e8f6f8e62695d1ce9e4e1d68aa36c1cd2cfd15340213f3423e",
            blockHash: "0xe0e02b2c5eae2484fd3be314282c51ec1ce65cb07a251dbcb7f21c129279d83a",
            nonce: 0,
            era: .init(blockNumber: 21410254, period: 128)
        )

        let runtimeVersion = runtimeVersionProvider.runtimeVersion(for: meta)
        XCTAssertEqual(runtimeVersion, .v15)

        let preImage = try XCTUnwrap(txBuilder.buildForSign(amount: amount, destination: destination, meta: meta))
        sizeTester.testTxSize(preImage)

        let signature = try XCTUnwrap(signEd25519(message: preImage, privateKey: privateKey))
        let image = try XCTUnwrap(txBuilder.buildForSend(amount: amount, destination: destination, meta: meta, signature: signature))

        let expectedPreImage = Data(
            hexString: """
            0x040000032EB287017C5CDE2940B5DD062D413F9D09F8AA44723FC80BF46B96C81AC23D07E7450FD352E6040000\
            0008750F001A000000E143F23803AC50E8F6F8E62695D1CE9E4E1D68AA36C1CD2CFD15340213F3423EE0E02B2C5E\
            AE2484FD3BE314282C51EC1CE65CB07A251DBCB7F21C129279D83A00
            """
        )
        let expectedImage = Data(
            hexString: """
            0x45028400AAC36941B9D4DEB53D6C4A8CBADF0C25A509E39C83A7513C85DDF53B37AB4D5100E0D07A7BE3ED378AA9B004FBE50BE72\
            3094B6754B089D118983FEB4D4038FBF230233CB1018F49F6335F2D4674C842FD29E7CC8EEEDB1365E455769310DF8905E6040000000\
            40000032EB287017C5CDE2940B5DD062D413F9D09F8AA44723FC80BF46B96C81AC23D07E7450FD352
            """
        )
        XCTAssertEqual(preImage, expectedPreImage)

        let (imageWithoutSignature, expectedImageWithoutSignature) = try removeSignature(
            image: image,
            expectedImage: expectedImage,
            signature: signature
        )
        XCTAssertEqual(imageWithoutSignature, expectedImageWithoutSignature)
    }

    // MARK: - Azero substrate runtime v14

    func testAzeroTransactionEd25519RuntimeV14() throws {
        try testAzeroTransactionRuntimeV14(curve: .ed25519)
    }

    func testAzeroTransactionEd25519Slip0010RuntimeV14() throws {
        try testAzeroTransactionRuntimeV14(curve: .ed25519_slip0010)
    }

    private func testAzeroTransactionRuntimeV14(curve: EllipticCurve) throws {
        let toAddress = Data(hexString: "0x8eaf04151687736326c9fea17e25fc5287613693c912909cb226aa4794f26a48")
        let privateKey = Data(hexString: "0xabf8e5bdbe30c65656c0a3cbd181ff8a56294a69dfedd27982aace4a76909115")
        let publicKey = try XCTUnwrap(Curve25519.Signing.PrivateKey(rawRepresentation: privateKey).publicKey.rawRepresentation)
        let blockchain: Blockchain = .azero(curve: curve, testnet: false)
        let network = try XCTUnwrap(PolkadotNetwork(blockchain: blockchain))
        let runtimeVersionProvider = SubstrateRuntimeVersionProvider(network: network)

        let txBuilder = PolkadotTransactionBuilder(
            blockchain: blockchain,
            walletPublicKey: publicKey,
            network: network,
            runtimeVersionProvider: runtimeVersionProvider
        )

        let amount = Amount(with: blockchain, value: 12345 / blockchain.decimalValue)
        let destination = try XCTUnwrap(PolkadotAddressService(network: network).makeAddress(from: toAddress).value)
        let meta = PolkadotBlockchainMeta(
            specVersion: 17,
            transactionVersion: 3,
            genesisHash: "91b171bb158e2d3848fa23a9f1c25182fb8e20313b2c1eb49219da7a70ce90c3",
            blockHash: "0x343a3f4258fd92f5ca6ca5abdf473d86a78b0bcd0dc09c568ca594245cc8c642",
            nonce: 0,
            era: .init(blockNumber: 927699, period: 8)
        )

        let runtimeVersion = runtimeVersionProvider.runtimeVersion(for: meta)
        XCTAssertEqual(runtimeVersion, .v14)

        let preImage = try XCTUnwrap(txBuilder.buildForSign(amount: amount, destination: destination, meta: meta))
        sizeTester.testTxSize(preImage)

        let signature = try XCTUnwrap(signEd25519(message: preImage, privateKey: privateKey))
        let image = try XCTUnwrap(txBuilder.buildForSend(amount: amount, destination: destination, meta: meta, signature: signature))

        let expectedPreImage = Data(
            hexString: """
            0500008eaf04151687736326c9fea17e25fc5287613693c912909cb226aa4794f26a48e5c032000000110000000300000091b171\
            bb158e2d3848fa23a9f1c25182fb8e20313b2c1eb49219da7a70ce90c3343a3f4258fd92f5ca6ca5abdf473d86a78b0bcd0dc09c\
            568ca594245cc8c642
            """
        )
        let expectedImage = Data(
            hexString: """
            3102840088dc3417d5058ec4b4503e0c12ea1a0a89be200fe98922423d4334014fa6b0ee00e21967aec23f0d20809ea476bed495\
            2b21bd537d8319158bf0ab7bf3fae1168ec6b7915388f930a4e2efd4c87b20fec513182eecbcb8f931a31cc62608e203073200000\
            00500008eaf04151687736326c9fea17e25fc5287613693c912909cb226aa4794f26a48e5c0
            """
        )
        XCTAssertEqual(preImage, expectedPreImage)

        let (imageWithoutSignature, expectedImageWithoutSignature) = try removeSignature(
            image: image,
            expectedImage: expectedImage,
            signature: signature
        )
        XCTAssertEqual(imageWithoutSignature, expectedImageWithoutSignature)
    }

    // MARK: - Helpers

    private func removeSignature(image: Data, expectedImage: Data, signature: Data) throws -> (image: Data, expectedImage: Data) {
        let signatureRange = try XCTUnwrap(image.range(of: signature))

        var imageWithoutSignature = image
        imageWithoutSignature.removeSubrange(signatureRange)
        var expectedImageWithoutSignature = expectedImage
        expectedImageWithoutSignature.removeSubrange(signatureRange)

        return (imageWithoutSignature, expectedImageWithoutSignature)
    }

    private func signEd25519(message: Data, privateKey: Data) throws -> Data {
        return try Curve25519.Signing.PrivateKey(rawRepresentation: privateKey).signature(for: message)
    }
}
