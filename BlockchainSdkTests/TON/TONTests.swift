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
@testable import BlockchainSdk

class TONTests: XCTestCase {
    private var privateKey = try! Curve25519.Signing.PrivateKey(
        rawRepresentation: Data(hexString: "0x85fca134b3fe3fd523d8b528608d803890e26c93c86dc3d97b8d59c7b3540c97")
    )

    private func makeWalletManager(blockchain: BlockchainSdk.Blockchain) -> TONWalletManager {
        let walletPubKey = privateKey.publicKey.rawRepresentation
        let address = try! TonAddressService().makeAddress(
            for: .init(seedKey: walletPubKey, derivationType: .none),
            with: .default
        )

        let wallet = Wallet(blockchain: blockchain, addresses: [.default: address])
        return try! .init(
            wallet: wallet,
            networkService: TONNetworkService(providers: [], blockchain: blockchain)
        )
    }

    private func makeTransactionBuilder(wallet: BlockchainSdk.Wallet) -> TONTransactionBuilder {
        return TONTransactionBuilder.makeDummyBuilder(
            with: .init(
                wallet: wallet,
                inputPrivateKey: privateKey,
                sequenceNumber: 0
            )
        )
    }

    func testCorrectCoinTransactionEd25519() {
        testCorrectCoinTransaction(curve: .ed25519)
    }

    func testCorrectCoinTransactionEd25519Slip0010() {
        testCorrectCoinTransaction(curve: .ed25519_slip0010)
    }

    func testCorrectCoinTransaction(curve: EllipticCurve) {
        do {
            let blockchain = Blockchain.ton(curve: curve, testnet: true)
            let walletManager = makeWalletManager(blockchain: blockchain)
            let txBuilder = makeTransactionBuilder(wallet: walletManager.wallet)
            let input = try txBuilder.buildForSign(
                amount: .init(with: blockchain, value: 1),
                destination: "EQAoDMgtvyuYaUj-iHjrb_yZiXaAQWSm4pG2K7rWTBj9eOC2"
            )

            XCTAssertEqual(
                try! input.jsonString(),
                "{\"privateKey\":\"hfyhNLP+P9Uj2LUoYI2AOJDibJPIbcPZe41Zx7NUDJc=\",\"transfer\":{\"walletVersion\":\"WALLET_V4_R2\",\"dest\":\"EQAoDMgtvyuYaUj-iHjrb_yZiXaAQWSm4pG2K7rWTBj9eOC2\",\"amount\":\"1000000000\",\"mode\":3}}"
            )

            let output = try walletManager.buildTransaction(
                input: input,
                with: WalletCoreSignerTesterUtility(
                    privateKey: privateKey,
                    signatures: [
                        Data(hex: "0c88f60571fae5ae341b1af5910e0c07bd5676726cd7775c85159b5542cecb0c5e3f291d5f69f4f2da012524211c064ec2fc5f7f0c62b1ea236d6165d1fc2c09"),
                    ]
                )
            )

            XCTAssertEqual(output, "te6ccgICABoAAQAAA84AAAJFiAAkFwRyHvf/dUy7kDH1X6DgWJwTOQ0gSoVCd0RKy2RgfB4ABAABAZwMiPYFcfrlrjQbGvWRDgwHvVZ2cmzXd1yFFZtVQs7LDF4/KR1fafTy2gElJCEcBk7C/F9/DGKx6iNtYWXR/CwJKamjF/////8AAAAAAAMAAgFoQgAUBmQW35XMNKR/RDx1t/5MxLtAILJTcUjbFd1rJgx+vCHc1lAAAAAAAAAAAAAAAAAAAQADAAACATQABgAFAFEAAAAAKamjF+Cz/Mz+AoPMD4wQXGi1aQqrjFwWkqho5V6sqDbId5CFQAEU/wD0pBP0vPLICwAHAgEgAA0ACAT48oMI1xgg0x/TH9MfAvgju/Jk7UTQ0x/TH9P/9ATRUUO68qFRUbryogX5AVQQZPkQ8qP4ACSkyMsfUkDLH1Iwy/9SEPQAye1U+A8B0wchwACfbFGTINdKltMH1AL7AOgw4CHAAeMAIcAC4wABwAORMOMNA6TIyx8Syx/L/wAMAAsACgAJAAr0AMntVABsgQEI1xj6ANM/MFIkgQEI9Fnyp4IQZHN0cnB0gBjIywXLAlAFzxZQA/oCE8tqyx8Syz/Jc/sAAHCBAQjXGPoA0z/IVCBHgQEI9FHyp4IQbm90ZXB0gBjIywXLAlAGzxZQBPoCFMtqEssfyz/Jc/sAAgBu0gf6ANTUIvkABcjKBxXL/8nQd3SAGMjLBcsCIs8WUAX6AhTLaxLMzMlz+wDIQBSBAQj0UfKnAgIBSAAXAA4CASAAEAAPAFm9JCtvaiaECAoGuQ+gIYRw1AgIR6STfSmRDOaQPp/5g3gSgBt4EBSJhxWfMYQCASAAEgARABG4yX7UTQ1wsfgCAVgAFgATAgEgABUAFAAZrx32omhAEGuQ64WPwAAZrc52omhAIGuQ64X/wAA9sp37UTQgQFA1yH0BDACyMoHy//J0AGBAQj0Cm+hMYALm0AHQ0wMhcbCSXwTgItdJwSCSXwTgAtMfIYIQcGx1Z70ighBkc3RyvbCSXwXgA/pAMCD6RAHIygfL/8nQ7UTQgQFA1yH0BDBcgQEI9ApvoTGzkl8H4AXTP8glghBwbHVnupI4MOMNA4IQZHN0crqSXwbjDQAZABgAilAEgQEI9Fkw7UTQgQFA1yDIAc8W9ADJ7VQBcrCOI4IQZHN0coMesXCAGFAFywVQA88WI/oCE8tqyx/LP8mAQPsAkl8D4gB4AfoA9AQw+CdvIjBQCqEhvvLgUIIQcGx1Z4MesXCAGFAEywUmzxZY+gIZ9ADLaRfLH1Jgyz8gyYBA+wAG")
        } catch {
            XCTFail("Transaction build for sign is nil")
        }
    }

    func testCorrectCoinWithMemoTransactionEd25519() {
        testCorrectCoinWithMemoTransaction(curve: .ed25519)
    }

    func testCorrectCoinWithMemoTransactionEd25519Slip0010() {
        testCorrectCoinWithMemoTransaction(curve: .ed25519_slip0010)
    }

    func testCorrectCoinWithMemoTransaction(curve: EllipticCurve) {
        do {
            let blockchain = Blockchain.ton(curve: curve, testnet: true)
            let walletManager = makeWalletManager(blockchain: blockchain)
            let txBuilder = makeTransactionBuilder(wallet: walletManager.wallet)

            let input = try txBuilder.buildForSign(
                amount: .init(with: blockchain, value: 1),
                destination: "EQAoDMgtvyuYaUj-iHjrb_yZiXaAQWSm4pG2K7rWTBj9eOC2",
                params: .init(memo: "Hello world!")
            )

            XCTAssertEqual(
                try! input.jsonString(),
                "{\"privateKey\":\"hfyhNLP+P9Uj2LUoYI2AOJDibJPIbcPZe41Zx7NUDJc=\",\"transfer\":{\"walletVersion\":\"WALLET_V4_R2\",\"dest\":\"EQAoDMgtvyuYaUj-iHjrb_yZiXaAQWSm4pG2K7rWTBj9eOC2\",\"amount\":\"1000000000\",\"mode\":3,\"comment\":\"Hello world!\"}}"
            )

            let output = try walletManager.buildTransaction(
                input: input,
                with: WalletCoreSignerTesterUtility(
                    privateKey: privateKey,
                    signatures: [
                        Data(hex: "0c88f60571fae5ae341b1af5910e0c07bd5676726cd7775c85159b5542cecb0c5e3f291d5f69f4f2da012524211c064ec2fc5f7f0c62b1ea236d6165d1fc2c09"),
                    ]
                )
            )

            XCTAssertEqual(output, "te6ccgICABoAAQAAA94AAAJFiAAkFwRyHvf/dUy7kDH1X6DgWJwTOQ0gSoVCd0RKy2RgfB4ABAABAZwMiPYFcfrlrjQbGvWRDgwHvVZ2cmzXd1yFFZtVQs7LDF4/KR1fafTy2gElJCEcBk7C/F9/DGKx6iNtYWXR/CwJKamjF/////8AAAAAAAMAAgFoQgAUBmQW35XMNKR/RDx1t/5MxLtAILJTcUjbFd1rJgx+vCHc1lAAAAAAAAAAAAAAAAAAAQADACAAAAAASGVsbG8gd29ybGQhAgE0AAYABQBRAAAAACmpoxfgs/zM/gKDzA+MEFxotWkKq4xcFpKoaOVerKg2yHeQhUABFP8A9KQT9LzyyAsABwIBIAANAAgE+PKDCNcYINMf0x/THwL4I7vyZO1E0NMf0x/T//QE0VFDuvKhUVG68qIF+QFUEGT5EPKj+AAkpMjLH1JAyx9SMMv/UhD0AMntVPgPAdMHIcAAn2xRkyDXSpbTB9QC+wDoMOAhwAHjACHAAuMAAcADkTDjDQOkyMsfEssfy/8ADAALAAoACQAK9ADJ7VQAbIEBCNcY+gDTPzBSJIEBCPRZ8qeCEGRzdHJwdIAYyMsFywJQBc8WUAP6AhPLassfEss/yXP7AABwgQEI1xj6ANM/yFQgR4EBCPRR8qeCEG5vdGVwdIAYyMsFywJQBs8WUAT6AhTLahLLH8s/yXP7AAIAbtIH+gDU1CL5AAXIygcVy//J0Hd0gBjIywXLAiLPFlAF+gIUy2sSzMzJc/sAyEAUgQEI9FHypwICAUgAFwAOAgEgABAADwBZvSQrb2omhAgKBrkPoCGEcNQICEekk30pkQzmkD6f+YN4EoAbeBAUiYcVnzGEAgEgABIAEQARuMl+1E0NcLH4AgFYABYAEwIBIAAVABQAGa8d9qJoQBBrkOuFj8AAGa3OdqJoQCBrkOuF/8AAPbKd+1E0IEBQNch9AQwAsjKB8v/ydABgQEI9ApvoTGAC5tAB0NMDIXGwkl8E4CLXScEgkl8E4ALTHyGCEHBsdWe9IoIQZHN0cr2wkl8F4AP6QDAg+kQByMoHy//J0O1E0IEBQNch9AQwXIEBCPQKb6Exs5JfB+AF0z/IJYIQcGx1Z7qSODDjDQOCEGRzdHK6kl8G4w0AGQAYAIpQBIEBCPRZMO1E0IEBQNcgyAHPFvQAye1UAXKwjiOCEGRzdHKDHrFwgBhQBcsFUAPPFiP6AhPLassfyz/JgED7AJJfA+IAeAH6APQEMPgnbyIwUAqhIb7y4FCCEHBsdWeDHrFwgBhQBMsFJs8WWPoCGfQAy2kXyx9SYMs/IMmAQPsABg==")
        } catch {
            XCTFail("Transaction build for sign is nil")
        }
    }

    func testAddressServiceFactoryCreateCorrectTonAddressService() {
        EllipticCurve.allCases.forEach { curve in
            let addressService = AddressServiceFactory(
                blockchain: .ton(curve: curve, testnet: false)
            ).makeAddressService()

            XCTAssertTrue(
                addressService is TonAddressService
            )
        }
    }
}
