//
//  ChiaTests.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 10.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import CryptoKit
import TangemSdk
@testable import BlockchainSdk

class ChiaTests: XCTestCase {
    private let sizeUtility = TransactionSizeTesterUtility()
    private let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return encoder
    }()

    private let blockchain = Blockchain.chia(testnet: false)
    private let addressService = ChiaAddressService(isTestnet: false)
    private var decimals: Int { blockchain.decimalCount }

    private var testSignatures: [Data] {
        [
            "8C7470BEE98156B48A0909F6EF321DE86F073101399ACD160ACFEF57B943B6E76E22DC89D9C75ABBFAC97DC317FEA3CC0AD744F55E2EAA3AE3C099AFC89FE652B8B054C5AB1F6A11559A9BCFD132EE0F434BA4D7968A33EA1807CFAB097789B7",
            "93CFBA81239EAD3358E780073DCC9553097F377B217A8FE04CB07D4FC634F2A094425D8A9E8E2373880AD944EDB55ECF16D59F031986E9EFEB92290C3E7285227890E7FC3EAFFC84B84F225E62CFA5ED681DCE6993C9845543AA493180B28B04",
        ].map {
            Data(hexString: $0)
        }
    }

    func testConditionSpend() throws {
        let address = "txch14gxuvfmw2xdxqnws5agt3ma483wktd2lrzwvpj3f6jvdgkmf5gtq8g3aw3"
        let amount: Int64 = 235834596465
        let encodedAmount = amount.chiaEncoded

        let solution1 = try "ffffff33ffa0" +
            ChiaPuzzleUtils().getPuzzleHash(from: address).hexString.lowercased() + "ff8" + String(encodedAmount.count) + encodedAmount.hexString.lowercased() + "808080"

        let condition = try CreateCoinCondition(
            destinationPuzzleHash: ChiaPuzzleUtils().getPuzzleHash(from: address),
            amount: amount
        ).toProgram()

        let solution2 = try ClvmProgram.from(list: [ClvmProgram.from(list: [condition])]).serialize().hexString.lowercased()

        XCTAssertEqual(solution1.lowercased(), solution2.lowercased())
    }

    func testTransactionVector1() throws {
        let walletPublicKey = Data(hexString: "8FAC07255C7F3FE670E21E49CC5E70328F4181440A535CC18CF369FD280BA18FA26E28B52035717DB29BFF67105894B2")
        let sendValue = Decimal(stringValue: "0.0003")!
        let feeValue = Decimal(stringValue: "0.000000164238")!
        let destinationAddress = "xch1g36l3auawuejw3nvq08p29lw4wst4qrq9hddvtn9vv9nz822avgsrwte2v"
        let sourceAddress = try addressService.makeAddress(from: walletPublicKey)

        let transactionBuilder = ChiaTransactionBuilder(
            isTestnet: blockchain.isTestnet,
            walletPublicKey: walletPublicKey
        )

        let unspentCoins = [
            ChiaCoin(
                amount: 5199843583,
                parentCoinInfo: "0x34ddaf3f1500f45b2afe2d8783f8abbde57f82be02bf2f6661095c6b20cd12cb",
                puzzleHash: "0x9488ae2f6f0d2655aca94c6e658fdc31bd2217f74d676407112c0558d3d217d2"
            ),
        ]

        transactionBuilder.setUnspent(coins: unspentCoins)

        let amountToSend = Amount(with: blockchain, value: sendValue)
        let fee = Fee(Amount(with: amountToSend, value: feeValue))

        let transactionData = Transaction(
            amount: amountToSend,
            fee: fee,
            sourceAddress: sourceAddress.value,
            destinationAddress: destinationAddress,
            changeAddress: sourceAddress.value
        )

        let expectedHashToSign1 = Data(hexString: "8242AB52301FF9B0DDBD5C3219729720794D96C4BDE074BEC3FB4FEFBAC5AA37831B02578BF5C3AAAF37835F9B83C29709B3DF84D9A33CCB6700CCC2B3FFF9777603CD4F12A3EE3F26C2F425B6998BA9F586E5ADF5BCBBD1935995607C9E0DC0")

        let expectedSignedTransaction = ChiaSpendBundle(
            aggregatedSignature: "a1af85f8f921d18c1e6a81481d3e9cbf89caad7632a825dbbdeefa4c7a918903436f0b37cad1156dfd90ae94d2c0270d08e07190543dcd4e0e2a94ae2f15960ed3adb40e7ac1166bd5bfbfcc536389cfe0e1967db9ff00d09df1a1e3210460ee",
            coinSpends: [
                ChiaCoinSpend(
                    coin: unspentCoins[0],
                    puzzleReveal: "ff02ffff01ff02ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff0bff80808080ff80808080ff0b80ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b08fac07255c7f3fe670e21e49cc5e70328f4181440a535cc18cf369fd280ba18fa26e28b52035717db29bff67105894b2ff018080",
                    solution: "ffffff33ffa04475f8f79d773327466c03ce1517eeaba0ba80602ddad62e65630b311d4aeb11ff8411e1a30080ffff33ffa09488ae2f6f0d2655aca94c6e658fdc31bd2217f74d676407112c0558d3d217d2ff8501240b2c71808080"
                ),
            ]
        )

        let signature1 = Data(hexString: "A1AF85F8F921D18C1E6A81481D3E9CBF89CAAD7632A825DBBDEEFA4C7A918903436F0B37CAD1156DFD90AE94D2C0270D08E07190543DCD4E0E2A94AE2F15960ED3ADB40E7AC1166BD5BFBFCC536389CFE0E1967DB9FF00D09DF1A1E3210460EE")

        let buildToSignResult = try transactionBuilder.buildForSign(transaction: transactionData)
        let signedTransaction = try transactionBuilder.buildToSend(signatures: [signature1])

        XCTAssertEqual(buildToSignResult, [expectedHashToSign1])
        try XCTAssertEqual(jsonEncoder.encode(signedTransaction).hexString, jsonEncoder.encode(expectedSignedTransaction).hexString)
    }

    func testTransactionVector2() throws {
        let walletPublicKey = Data(hexString: "a259d941e9c70adb0dfa5b7ddc399d7eda3fe263b24cfd8123114b6c89a2e8c5263d063f48dabf50d72c05a2afc0f4fc")

        let sendValue = Decimal(stringValue: "0.02")!
        let feeValue = Decimal(stringValue: "0.000000027006")!
        let destinationAddress = "xch1m2g36ha9krk4xr7aazzhl98ghy5gzklxtrga3ce62zf6at7ef72s22xhyx"
        let sourceAddress = try addressService.makeAddress(from: walletPublicKey)

        let transactionBuilder = ChiaTransactionBuilder(
            isTestnet: blockchain.isTestnet,
            walletPublicKey: walletPublicKey
        )

        let unspentCoins = [
            ChiaCoin(
                amount: 98030270081,
                parentCoinInfo: "0x352edeba78e03024c377790db1ad7b0ade3ecc412b17c4d3a149138d1f5229ee",
                puzzleHash: "0x4475f8f79d773327466c03ce1517eeaba0ba80602ddad62e65630b311d4aeb11"
            ),
            ChiaCoin(
                amount: 6000000000,
                parentCoinInfo: "0xea2f576d1225fbfe485bc8b605b1a6abd111592925b2e0113d3041aeb7efb684",
                puzzleHash: "0x4475f8f79d773327466c03ce1517eeaba0ba80602ddad62e65630b311d4aeb11"
            ),
        ]

        transactionBuilder.setUnspent(coins: unspentCoins)

        let amountToSend = Amount(with: blockchain, value: sendValue)
        let fee = Fee(Amount(with: amountToSend, value: feeValue))

        let transactionData = Transaction(
            amount: amountToSend,
            fee: fee,
            sourceAddress: sourceAddress.value,
            destinationAddress: destinationAddress,
            changeAddress: sourceAddress.value
        )

        let hashToSignes = [
            "A45B057958AF4E155FDF2470F43BE8E2B26A9084EC28A34021FBE0F288881E197A73CC27FF88E82DB4C6BD0DD9D5A55A0B080381D4C4314C2473B2C4325BED52989D810869D7466540B0A896EF79011550E34C0B0AB6BB61429A7AA7699DF9EF",
            "AED861A416CD4B3F06B80658C86B5A66B7998988382F5BE448CAC67C4097F78E3F25E1976F70C033370DDF84A69AA7C0186B1EC7D693D87B21B5B03B35C3B1A0E6BDF1487D70994D05E5F151D3F84F70EEE322D1662B19F8873011392823950B",
        ].map {
            Data(hexString: $0)
        }

        let expectedSignedTransaction = ChiaSpendBundle(
            aggregatedSignature: "98e46525cfef4e221e2e1813a3738e73c5be98b50e6f092e7a28f1e51bd5306e4d4e9859159bb507543117e74688732601969087ead4ae26c132a8ddea3052fa4b41a409ebbe0ab63d03c43be76e38047ec77a31c7db5b62c12c877c36193a2e",
            coinSpends: [
                ChiaCoinSpend(
                    coin: unspentCoins[0],
                    puzzleReveal: "ff02ffff01ff02ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff0bff80808080ff80808080ff0b80ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b0a259d941e9c70adb0dfa5b7ddc399d7eda3fe263b24cfd8123114b6c89a2e8c5263d063f48dabf50d72c05a2afc0f4fcff018080",
                    solution: "ffffff33ffa0da911d5fa5b0ed530fdde8857f94e8b928815be658d1d8e33a5093aeafd94f95ff8504a817c80080ffff33ffa04475f8f79d773327466c03ce1517eeaba0ba80602ddad62e65630b311d4aeb11ff85139097c103808080"
                ),
                ChiaCoinSpend(
                    coin: unspentCoins[1],
                    puzzleReveal: "ff02ffff01ff02ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff0bff80808080ff80808080ff0b80ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b0a259d941e9c70adb0dfa5b7ddc399d7eda3fe263b24cfd8123114b6c89a2e8c5263d063f48dabf50d72c05a2afc0f4fcff018080",
                    solution: "ffffff01808080"
                ),
            ]
        )

        let signatures = [
            "A91765A3A213BC635431E6B3750F75153CC80E607AC8CC1A297FF2EE7CAC3B7A2A2A67513FCA1A83083A73F121A7AD64124FD684611C5F625DD70E098893B4292D378E087F25ECEB6F6942324F10A461820C006549B307A9CEB79B362AB2D7D3",
            "A9838F9A7F05C3B7175A963C3AF8EEB7DB2B9C61A6247EA6C5224CDC2DABA26B811BFBDF396288C34ECA6ABE3E98E0740FDD24033FBC659695C137F5793E4FAF61F9657DC41C09FE9D336A1F0D7563142C876B3842135CD2965D50FFD31C541A",
        ].map {
            Data(hexString: $0)
        }

        let buildToSignResult = try transactionBuilder.buildForSign(transaction: transactionData)
        let signedTransaction = try transactionBuilder.buildToSend(signatures: signatures)

        XCTAssertEqual(buildToSignResult, hashToSignes)
        try XCTAssertEqual(jsonEncoder.encode(signedTransaction).hexString, jsonEncoder.encode(expectedSignedTransaction).hexString)
    }

    func testSizeTransaction() {
        sizeUtility.testTxSizes(testSignatures)
    }

    func testNegativeChiaEncoded() {
        let amountValue: Int64 = 10000000
        let encodedValue = amountValue.chiaEncoded

        XCTAssertEqual(encodedValue.hexString, "00989680")
    }

    func testPositiveChiaEncoded() {
        let amountValue: Int64 = 235834596465
        let encodedValue = amountValue.chiaEncoded

        XCTAssertEqual(encodedValue.hexString, "36E8D65C71")
    }
}
