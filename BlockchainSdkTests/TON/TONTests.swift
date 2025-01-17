//
//  TONTests.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 20.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import CryptoKit
import TangemSdk
import WalletCore
import BigInt
@testable import BlockchainSdk

class TONTests: XCTestCase {
    private var privateKey = try! Curve25519.Signing.PrivateKey(
        rawRepresentation: Data(hexString: "0x85fca134b3fe3fd523d8b528608d803890e26c93c86dc3d97b8d59c7b3540c97")
    )

    private func makeWalletManager(blockchain: BlockchainSdk.Blockchain) throws -> TONWalletManager {
        let walletPubKey = privateKey.publicKey.rawRepresentation

        // UQASC4I5D3v_uqZdyBj6r9BwLE4JnIaQJUKhO6IlZbIwPj4G
        let address = try WalletCoreAddressService(coin: .ton).makeAddress(
            for: .init(seedKey: walletPubKey, derivationType: .none),
            with: .default
        )

        let wallet = Wallet(blockchain: blockchain, addresses: [.default: address])

        return try .init(
            wallet: wallet,
            transactionBuilder: .init(wallet: wallet),
            networkService: TONNetworkService(providers: [], blockchain: blockchain)
        )
    }

    func testCorrectCoinTransactionEd25519() throws {
        try testCorrectCoinTransaction(curve: .ed25519)
    }

    func testCorrectCoinTransactionEd25519Slip0010() throws {
        try testCorrectCoinTransaction(curve: .ed25519_slip0010)
    }

    // https://tonscan.org/tx/77f72e4096f2ae315ff7b0906569f9aa450686b11a40e65c9adb8690587bffa4
    func testCorrectCoinTransaction(curve: EllipticCurve) throws {
        let blockchain = Blockchain.ton(curve: curve, testnet: false)
        let walletManager = try makeWalletManager(blockchain: blockchain)
        let txBuilder = TONTransactionBuilder(wallet: walletManager.wallet)

        let buildInput = TONTransactionInput(
            amount: .init(with: blockchain, value: 0.05),
            destination: "UQCFArsfuLucMirvHCyGyMkmIbQ26_BcFFG7mHfOxlVpF0Wv",
            expireAt: 1733405859,
            jettonWalletAddress: nil,
            params: TONTransactionParams(memo: "123456")
        )

        let buildForSign = try txBuilder.buildForSign(buildInput: buildInput)

        XCTAssertEqual("2980e02f4d5e84dc9017abd504d9ac79189f821b525e890fe8034ad32edfc3c7".lowercased(), buildForSign.hexString.lowercased())

        let expectedSignature = Data(hex: "d32e3e16841f2901afaa3ad2448896c8a4b0eb6b2fb7eb95ccd428cb4499be7c869926ce557323fd01f684407a75e9ef1e64bc004f2c7192c9bdc4b062198f03")

        let buildForSend = try txBuilder.buildForSend(buildInput: buildInput, signature: expectedSignature)

        XCTAssertEqual(buildForSend, "te6cckECGgEAA78AAkWIACQXBHIe9/91TLuQMfVfoOBYnBM5DSBKhUJ3RErLZGB8HgECAgE0AwQBnNMuPhaEHykBr6o60kSIlsiksOtrL7frlczUKMtEmb58hpkmzlVzI/0B9oRAenXp7x5kvABPLHGSyb3EsGIZjwMpqaMX/////wAAAAAAAwUBFP8A9KQT9LzyyAsGAFEAAAAAKamjF+Cz/Mz+AoPMD4wQXGi1aQqrjFwWkqho5V6sqDbId5CFQAFoQgBCgV2P3F3OGRV3jhZDZGSTENobdfguCijdzDvnYyq0i6AX14QAAAAAAAAAAAAAAAAAAQcCASAICQAUAAAAADEyMzQ1NgIBSAoLBPjygwjXGCDTH9Mf0x8C+CO78mTtRNDTH9Mf0//0BNFRQ7ryoVFRuvKiBfkBVBBk+RDyo/gAJKTIyx9SQMsfUjDL/1IQ9ADJ7VT4DwHTByHAAJ9sUZMg10qW0wfUAvsA6DDgIcAB4wAhwALjAAHAA5Ew4w0DpMjLHxLLH8v/DA0ODwLm0AHQ0wMhcbCSXwTgItdJwSCSXwTgAtMfIYIQcGx1Z70ighBkc3RyvbCSXwXgA/pAMCD6RAHIygfL/8nQ7UTQgQFA1yH0BDBcgQEI9ApvoTGzkl8H4AXTP8glghBwbHVnupI4MOMNA4IQZHN0crqSXwbjDRARAgEgEhMAbtIH+gDU1CL5AAXIygcVy//J0Hd0gBjIywXLAiLPFlAF+gIUy2sSzMzJc/sAyEAUgQEI9FHypwIAcIEBCNcY+gDTP8hUIEeBAQj0UfKnghBub3RlcHSAGMjLBcsCUAbPFlAE+gIUy2oSyx/LP8lz+wACAGyBAQjXGPoA0z8wUiSBAQj0WfKnghBkc3RycHSAGMjLBcsCUAXPFlAD+gITy2rLHxLLP8lz+wAACvQAye1UAHgB+gD0BDD4J28iMFAKoSG+8uBQghBwbHVngx6xcIAYUATLBSbPFlj6Ahn0AMtpF8sfUmDLPyDJgED7AAYAilAEgQEI9Fkw7UTQgQFA1yDIAc8W9ADJ7VQBcrCOI4IQZHN0coMesXCAGFAFywVQA88WI/oCE8tqyx/LP8mAQPsAkl8D4gIBIBQVAFm9JCtvaiaECAoGuQ+gIYRw1AgIR6STfSmRDOaQPp/5g3gSgBt4EBSJhxWfMYQCAVgWFwARuMl+1E0NcLH4AD2ynftRNCBAUDXIfQEMALIygfL/8nQAYEBCPQKb6ExgAgEgGBkAGa3OdqJoQCBrkOuF/8AAGa8d9qJoQBBrkOuFj8CNR4py")
    }

    func testCorrectTokenTransactionEd25519() throws {
        try testCorrectTokenTransaction(curve: .ed25519)
    }

    func testCorrectTokenTransactionEd25519Slip0010() throws {
        try testCorrectTokenTransaction(curve: .ed25519_slip0010)
    }

    // https://tonviewer.com/transaction/a274b0bd0f6a90c1296c8a7ee305488852e9335e47230dcee0d6495dcad71692
    func testCorrectTokenTransaction(curve: EllipticCurve) throws {
        let blockchain = Blockchain.ton(curve: curve, testnet: false)
        let walletManager = try makeWalletManager(blockchain: blockchain)
        let txBuilder = TONTransactionBuilder(wallet: walletManager.wallet)

        txBuilder.sequenceNumber = 5

        let token = Token(
            name: "tether",
            symbol: "Tether",
            contractAddress: "EQCxE6mUtQJKFnGfaROTKOt1lZbDiiX1kCixRv7Nw2Id_sDs",
            decimalCount: 6
        )

        let amount = Amount(with: token, value: 0.1)

        let buildInput = TONTransactionInput(
            amount: amount,
            destination: "UQBzvZk8lobyrPW9Sf3vsXNYjpW-ixFqNtwyP9_RUkwLNeVx",
            expireAt: 1733419000,
            jettonWalletAddress: "UQBp_I7USZxSLmjcb6dMnQUtnmZbfWmpt5zdnolPsA-IaJ8l",
            params: nil
        )

        let buildForSign = try txBuilder.buildForSign(buildInput: buildInput)

        XCTAssertEqual("876b5fe635e5d538edef9e16746b7de19c1384c46a41302a15f7243d38285f9c".lowercased(), buildForSign.hexString.lowercased())

        let expectedSignature = Data(hex: "6AAD07AEB57E99A528BF5EE5649EC4CEFF34F301E1C6502E25919855B47667CAE33B0D04E7E5D8082B998442EA1DC41D4277ACE8D02621187682DDD270067D08")

        let buildForSend = try txBuilder.buildForSend(buildInput: buildInput, signature: expectedSignature)

        XCTAssertEqual(buildForSend, "te6cckECBAEAAQQAAUWIACQXBHIe9/91TLuQMfVfoOBYnBM5DSBKhUJ3RErLZGB8DAEBnGqtB661fpmlKL9e5WSexM7/NPMB4cZQLiWRmFW0dmfK4zsNBOfl2AgrmYRC6h3EHUJ3rOjQJiEYdoLd0nAGfQgpqaMXZ1Hf+AAAAAUAAwIBaEIANP5HaiTOKRc0bjfTpk6Cls8zLb601NvObs9Ep9gHxDQgF9eEAAAAAAAAAAAAAAAAAAEDAKgPin6lAAAAAAAAAAAwGGoIAOd7MnktDeVZ63qT+99i5rEdK30WItRtuGR/v6KkmBZrAASC4I5D3v/uqZdyBj6r9BwLE4JnIaQJUKhO6IlZbIwPggKtrAfE")
    }
}
