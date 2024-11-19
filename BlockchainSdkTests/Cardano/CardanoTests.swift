//
//  CardanoTests.swift
//  BlockchainSdkTests
//
//  Created by Sergey Balashov on 15.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
import WalletCore
@testable import BlockchainSdk

class CardanoTests: XCTestCase {
    var transactionBuilder: CardanoTransactionBuilder!
    let blockchain = BlockchainSdk.Blockchain.cardano(extended: false)
    let coinType = CoinType.cardano

    override func setUp() {
        super.setUp()
        transactionBuilder = CardanoTransactionBuilder()
    }

    // Successful transaction
    // https://cardanoscan.io/transaction/db2306d819d848f67f70ab898028d9827e5d1fccc7033531534fdd39e93a796e
    func testSignTransfer() throws {
        let utxos = [
            CardanoUnspentOutput(
                address: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn",
                amount: 2500000,
                outputIndex: 0,
                transactionHash: "1992f01dfd9a94d7a2896617a96b3deb5f007ca32e8860e7c1720714ae6a17e5",
                assets: []
            ),
            CardanoUnspentOutput(
                address: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn",
                amount: 1450000,
                outputIndex: 0,
                transactionHash: "2a14228eb7d7ac30ed019ec139f0120e4538fb3f6d52dd97c8d416468ef87c24",
                assets: []
            ),
        ]

        transactionBuilder.update(outputs: utxos)

        let (_, parameters) = try transactionBuilder.getFee(
            amount: Amount(with: blockchain, value: 1.8),
            destination: "addr1q90uh2eawrdc9vaemftgd50l28yrh9lqxtjjh4z6dnn0u7ggasexxdyyk9f05atygnjlccsjsggtc87hhqjna32fpv5qeq96ls",
            source: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn"
        )

        let transaction = Transaction(
            amount: Amount(with: blockchain, value: 1.8),
            fee: Fee(.zeroCoin(for: blockchain), parameters: parameters), // parameters is manandatory
            sourceAddress: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn",
            destinationAddress: "addr1q90uh2eawrdc9vaemftgd50l28yrh9lqxtjjh4z6dnn0u7ggasexxdyyk9f05atygnjlccsjsggtc87hhqjna32fpv5qeq96ls",
            changeAddress: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn"
        )

        let dataForSign = try transactionBuilder.buildForSign(transaction: transaction)
        XCTAssertEqual(
            dataForSign.hexString.lowercased(),
            "db2306d819d848f67f70ab898028d9827e5d1fccc7033531534fdd39e93a796e"
        )

        // Sign
        let signature = Data(hex: "d110d0ae92016c4edf0eefb2c54ad71b4e9b27f8427f6bd895e94f3beded57f839deecea4f50a3ff6730409b323fa2b07c1e1529e8ebbdebb5138b5ee2f4ab09")
        let publicKey = Data(hex: "de60f41ab5045ce1b9b37e386570ed63499a53ee93ca3073e54a80065678384d")

        let signatureInfo = SignatureInfo(signature: signature, publicKey: publicKey, hash: dataForSign)
        let encoded = try transactionBuilder.buildForSend(transaction: transaction, signature: signatureInfo)
        XCTAssertEqual(
            encoded.hexString.lowercased(),
            "83a400828258201992f01dfd9a94d7a2896617a96b3deb5f007ca32e8860e7c1720714ae6a17e5008258202a14228eb7d7ac30ed019ec139f0120e4538fb3f6d52dd97c8d416468ef87c24000182825839015fcbab3d70db82b3b9da5686d1ff51c83b97e032e52bd45a6ce6fe7908ec32633484b152fa756444e5fc62128210bc1fd7b8253ec5490b281a001b774082581d6127a5b0988b7a6f9dce66d48ff48a3f9a9ef8d24376a937f179ed02171a001e3a6d021a00029403031a0b532b80a10081825820de60f41ab5045ce1b9b37e386570ed63499a53ee93ca3073e54a80065678384d5840d110d0ae92016c4edf0eefb2c54ad71b4e9b27f8427f6bd895e94f3beded57f839deecea4f50a3ff6730409b323fa2b07c1e1529e8ebbdebb5138b5ee2f4ab09f6"
        )
    }

    // Successful transaction
    // https://cardanoscan.io/transaction/03946fe122634d05e93219fde628ce55a5e0d06f23afa456864897357c5dade8
    func testSignTransferFromLegacy() throws {
        let utxos = [
            CardanoUnspentOutput(
                address: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn",
                amount: 1981037,
                outputIndex: 1,
                transactionHash: "db2306d819d848f67f70ab898028d9827e5d1fccc7033531534fdd39e93a796e",
                assets: []
            ),
            CardanoUnspentOutput(
                address: "Ae2tdPwUPEZH7acU3Qm7L8HdDmw3fGMZ4Gg1wzfB9AMQH2nEgmjtSCWbFsJ",
                amount: 1300000,
                outputIndex: 0,
                transactionHash: "848c0861a3dc02a806d71cb35de83ffbc2a8553d161e2449c37572d7c2de44a7",
                assets: []
            ),
        ]

        transactionBuilder.update(outputs: utxos)

        let (_, parameters) = try transactionBuilder.getFee(
            amount: Amount(with: blockchain, value: 1.3),
            destination: "Ae2tdPwUPEZ4kps4As3f38H3gyjMs2YoMdJVMCq3UQzK4zhLunRriZpfbhs",
            source: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn"
        )

        let transaction = Transaction(
            amount: Amount(with: blockchain, value: 1.3),
            fee: Fee(.zeroCoin(for: blockchain), parameters: parameters), // parameters is manandatory
            sourceAddress: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn",
            destinationAddress: "Ae2tdPwUPEZ4kps4As3f38H3gyjMs2YoMdJVMCq3UQzK4zhLunRriZpfbhs",
            changeAddress: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn"
        )

        let dataForSign = try transactionBuilder.buildForSign(transaction: transaction)
        XCTAssertEqual(dataForSign.hexString.lowercased(), "03946fe122634d05e93219fde628ce55a5e0d06f23afa456864897357c5dade8")

        // Sign
        let signature = Data(hex: "d0cd5a183e63dce8f0d5bc6d617bbc2f3aa982fd24ece4e29eb10abb69c00bc8dd9d353f35084c5bcc9f81d4599e9c67980ebce32e3462951116ee39da1da406")
        let publicKey = Data(hex: "de60f41ab5045ce1b9b37e386570ed63499a53ee93ca3073e54a80065678384d")

        let signatureInfo = SignatureInfo(signature: signature, publicKey: publicKey, hash: dataForSign)
        let encoded = try transactionBuilder.buildForSend(transaction: transaction, signature: signatureInfo)

        XCTAssertEqual(
            encoded.hexString.lowercased(),
            "83a40082825820db2306d819d848f67f70ab898028d9827e5d1fccc7033531534fdd39e93a796e01825820848c0861a3dc02a806d71cb35de83ffbc2a8553d161e2449c37572d7c2de44a700018282582b82d818582183581c4fab3a1dbcaec5ed582dc34219b0147b972c35f201b73a446105719ea0001aa351d8aa1a0013d62082581d6127a5b0988b7a6f9dce66d48ff48a3f9a9ef8d24376a937f179ed02171a001b67f5021a0002d278031a0b532b80a20081825820de60f41ab5045ce1b9b37e386570ed63499a53ee93ca3073e54a80065678384d5840d0cd5a183e63dce8f0d5bc6d617bbc2f3aa982fd24ece4e29eb10abb69c00bc8dd9d353f35084c5bcc9f81d4599e9c67980ebce32e3462951116ee39da1da4060281845820de60f41ab5045ce1b9b37e386570ed63499a53ee93ca3073e54a80065678384d5840d0cd5a183e63dce8f0d5bc6d617bbc2f3aa982fd24ece4e29eb10abb69c00bc8dd9d353f35084c5bcc9f81d4599e9c67980ebce32e3462951116ee39da1da4065820000000000000000000000000000000000000000000000000000000000000000041a0f6"
        )
    }

    // Successful transaction
    // https://cardanoscan.io/transaction/3ac6b76c63e109494823fe13e6f6d52544896a5ab81ae711ce56f039d6777bd1
    func testSignTransferToken() throws {
        let utxos = [
            CardanoUnspentOutput(
                address: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn",
                amount: 1796085,
                outputIndex: 1,
                transactionHash: "03946fe122634d05e93219fde628ce55a5e0d06f23afa456864897357c5dade8",
                assets: []
            ),
            CardanoUnspentOutput(
                address: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn",
                amount: 1500000,
                outputIndex: 0,
                transactionHash: "482d88eb2d3b40b8a4e6bb8545cef842a5703e8f9eab9e3caca5c2edd1f31a7f",
                assets: [
                    CardanoUnspentOutput.Asset(
                        policyID: "f43a62fdc3965df486de8a0d32fe800963589c41b38946602a0dc535",
                        assetNameHex: "41474958",
                        amount: 50000000
                    ),
                ]
            ),
            CardanoUnspentOutput(
                address: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn",
                amount: 1127821,
                outputIndex: 0,
                transactionHash: "967e971cb5bcb1723ef24140c6d6689eb6453548ee47478996dcc6677ce7f62f",
                assets: []
            ),
            CardanoUnspentOutput(
                address: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn",
                amount: 3384392,
                outputIndex: 1,
                transactionHash: "d5958a70c20fdc7aa3537bf830730b1cef3dd5b2d12dc0360be130a18df71cd9",
                assets: [
                    CardanoUnspentOutput.Asset(
                        policyID: "f43a62fdc3965df486de8a0d32fe800963589c41b38946602a0dc535",
                        assetNameHex: "41474958",
                        amount: 42070000
                    ),
                ]
            ),
        ]

        transactionBuilder.update(outputs: utxos)

        let token = Token(
            name: "SingularityNET",
            symbol: "AGIX",
            contractAddress: "asset1wwyy88f8u937hz7kunlkss7gu446p6ed5gdfp6",
            decimalCount: 8
        )

        let (_, parameters) = try transactionBuilder.getFee(
            amount: Amount(with: blockchain, type: .token(value: token), value: 0.65),
            destination: "addr1qx55ymlqemndq8gluv40v58pu76a2tp4mzjnyx8n6zrp2vtzrs43a0057y0edkn8lh9su8vh5lnhs4npv6l9tuvncv8swc7t08",
            source: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn"
        )

        let transaction = Transaction(
            amount: Amount(with: blockchain, type: .token(value: token), value: 0.65),
            fee: Fee(.zeroCoin(for: blockchain), parameters: parameters), // parameters is manandatory
            sourceAddress: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn",
            destinationAddress: "addr1qx55ymlqemndq8gluv40v58pu76a2tp4mzjnyx8n6zrp2vtzrs43a0057y0edkn8lh9su8vh5lnhs4npv6l9tuvncv8swc7t08",
            changeAddress: "addr1vyn6tvyc3daxl8wwvm2glay287dfa7xjgdm2jdl308ksy9canqafn"
        )

        let dataForSign = try transactionBuilder.buildForSign(transaction: transaction)
        XCTAssertEqual(dataForSign.hexString.lowercased(), "3ac6b76c63e109494823fe13e6f6d52544896a5ab81ae711ce56f039d6777bd1")

        // Sign
        let signature = Data(hex: "a3c14e049b3192c64af175ff3650f9c0a6f833d168634b3ec73f2f5609bce107d2e39a1387c844bbe521bf3d11a63c4927f62a7c06dc40a8c28da74cb072d70d")
        let publicKey = Data(hex: "de60f41ab5045ce1b9b37e386570ed63499a53ee93ca3073e54a80065678384d")

        let signatureInfo = SignatureInfo(signature: signature, publicKey: publicKey, hash: dataForSign)
        let encoded = try transactionBuilder.buildForSend(transaction: transaction, signature: signatureInfo)

        XCTAssertEqual(
            encoded.hexString.lowercased(),
            "83a40084825820d5958a70c20fdc7aa3537bf830730b1cef3dd5b2d12dc0360be130a18df71cd90182582003946fe122634d05e93219fde628ce55a5e0d06f23afa456864897357c5dade801825820482d88eb2d3b40b8a4e6bb8545cef842a5703e8f9eab9e3caca5c2edd1f31a7f00825820967e971cb5bcb1723ef24140c6d6689eb6453548ee47478996dcc6677ce7f62f00018282583901a9426fe0cee6d01d1fe32af650e1e7b5d52c35d8a53218f3d0861531621c2b1ebdf4f11f96da67fdcb0e1d97a7e778566166be55f193c30f821a00160a5ba1581cf43a62fdc3965df486de8a0d32fe800963589c41b38946602a0dc535a144414749581a03dfd24082581d6127a5b0988b7a6f9dce66d48ff48a3f9a9ef8d24376a937f179ed0217821a005e6b9da1581cf43a62fdc3965df486de8a0d32fe800963589c41b38946602a0dc535a144414749581a019d0e30021a0002af32031a0b532b80a10081825820de60f41ab5045ce1b9b37e386570ed63499a53ee93ca3073e54a80065678384d5840a3c14e049b3192c64af175ff3650f9c0a6f833d168634b3ec73f2f5609bce107d2e39a1387c844bbe521bf3d11a63c4927f62a7c06dc40a8c28da74cb072d70df6"
        )
    }

    func testSignTransferExtendedKey() throws {
        let utxos = [
            CardanoUnspentOutput(
                address: "addr1q8043m5heeaydnvtmmkyuhe6qv5havvhsf0d26q3jygsspxlyfpyk6yqkw0yhtyvtr0flekj84u64az82cufmqn65zdsylzk23",
                amount: 1500000,
                outputIndex: 1,
                transactionHash: "f074134aabbfb13b8aec7cf5465b1e5a862bde5cb88532cc7e64619179b3e767",
                assets: []
            ),
            CardanoUnspentOutput(
                address: "addr1q8043m5heeaydnvtmmkyuhe6qv5havvhsf0d26q3jygsspxlyfpyk6yqkw0yhtyvtr0flekj84u64az82cufmqn65zdsylzk23",
                amount: 6500000,
                outputIndex: 0,
                transactionHash: "554f2fd942a23d06835d26bbd78f0106fa94c8a551114a0bef81927f66467af0",
                assets: []
            ),
        ]

        transactionBuilder.update(outputs: utxos)

        let (_, parameters) = try transactionBuilder.getFee(
            amount: Amount(with: blockchain, value: 7),
            destination: "addr1q92cmkgzv9h4e5q7mnrzsuxtgayvg4qr7y3gyx97ukmz3dfx7r9fu73vqn25377ke6r0xk97zw07dqr9y5myxlgadl2s0dgke5",
            source: "addr1q8043m5heeaydnvtmmkyuhe6qv5havvhsf0d26q3jygsspxlyfpyk6yqkw0yhtyvtr0flekj84u64az82cufmqn65zdsylzk23"
        )

        let transaction = Transaction(
            amount: Amount(with: blockchain, value: 7),
            fee: Fee(.zeroCoin(for: blockchain), parameters: parameters), // parameters is manandatory
            sourceAddress: "addr1q8043m5heeaydnvtmmkyuhe6qv5havvhsf0d26q3jygsspxlyfpyk6yqkw0yhtyvtr0flekj84u64az82cufmqn65zdsylzk23",
            destinationAddress: "addr1q92cmkgzv9h4e5q7mnrzsuxtgayvg4qr7y3gyx97ukmz3dfx7r9fu73vqn25377ke6r0xk97zw07dqr9y5myxlgadl2s0dgke5",
            changeAddress: "addr1q8043m5heeaydnvtmmkyuhe6qv5havvhsf0d26q3jygsspxlyfpyk6yqkw0yhtyvtr0flekj84u64az82cufmqn65zdsylzk23"
        )

        let dataForSign = try transactionBuilder.buildForSign(transaction: transaction)
        XCTAssertEqual(
            dataForSign.hexString.lowercased(),
            "b4f4bc9bc56de11d3a45d640e935108fcb57cd53945257516c0a9dc683077b04"
        )

        // Sign
        let signature = Data(hex: "f0a916cf55df99f595b49b3ead2052a17fdf3357b2e04c97c0144b1ee7a88f9a33883d9483e9c9c54cf7d496ac8c7aa31b4eb23a8a2c277fab8e406ba7af2c05")
        let publicKey = Data(hex: "6d8a0b425bd2ec9692af39b1c0cf0e51caa07a603550e22f54091e872c7df29003391c68824881ae3fc23a56a1a75ada3b96382db502e37564e84a5413cfaf12e554163344aafc2bbefe778a6953ddce0583c2f8e0a0686929c020ca33e06932154425dfbb01a2c5c042da411703603f89af89e57faae2946e2a5c18b1c5ca0e")
        let signatureInfo = SignatureInfo(signature: signature, publicKey: publicKey, hash: dataForSign)
        let encoded = try transactionBuilder.buildForSend(transaction: transaction, signature: signatureInfo)
        XCTAssertEqual(
            encoded.hexString.lowercased(),
            "83a40082825820554f2fd942a23d06835d26bbd78f0106fa94c8a551114a0bef81927f66467af000825820f074134aabbfb13b8aec7cf5465b1e5a862bde5cb88532cc7e64619179b3e76701018282583901558dd902616f5cd01edcc62870cb4748c45403f1228218bee5b628b526f0ca9e7a2c04d548fbd6ce86f358be139fe680652536437d1d6fd51a006acfc082583901df58ee97ce7a46cd8bdeec4e5f3a03297eb197825ed5681191110804df22424b6880b39e4bac8c58de9fe6d23d79aaf44756389d827aa09b1a000ca96c021a000298d4031a0b532b80a100818258206d8a0b425bd2ec9692af39b1c0cf0e51caa07a603550e22f54091e872c7df2905840f0a916cf55df99f595b49b3ead2052a17fdf3357b2e04c97c0144b1ee7a88f9a33883d9483e9c9c54cf7d496ac8c7aa31b4eb23a8a2c277fab8e406ba7af2c05f6"
        )
    }
}
