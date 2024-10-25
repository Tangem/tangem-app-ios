//
//  RadiantTests.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 01.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import XCTest
import WalletCore
import BitcoinCore
@testable import BlockchainSdk

final class RadiantTests: XCTestCase {
    private let blockchain = Blockchain.radiant(testnet: false)

    private let privateKey = WalletCore.PrivateKey(data: Data(hexString: "079E750E71A7A2680380A4744C0E84567B1F8FC3C0AFD362D8326E1E676A4A15"))!
    private lazy var publicKey = privateKey.getPublicKeySecp256k1(compressed: true)

    private let scriptUtils = RadiantScriptUtils()

    // MARK: - Impementation

    func testScript() throws {
        let lockScript = BitcoinScript.lockScriptForAddress(address: "1vr9gJkNzTHv8DEQb4QBxAnQCxgzkFkbf", coin: .bitcoinCash)
        let legacyOutputScript = scriptUtils.buildOutputScript(address: "1vr9gJkNzTHv8DEQb4QBxAnQCxgzkFkbf").hexString

        XCTAssertEqual(lockScript.data.hexString.lowercased(), "76a9140a2f12f228cbc244c745f33a23f7e924cbf3b6ad88ac".lowercased())
        XCTAssertEqual(lockScript.data.hexString.lowercased(), legacyOutputScript.lowercased())
    }

    func testUtils() throws {
        let scripthash = try RadiantAddressUtils().prepareScriptHash(address: "1vr9gJkNzTHv8DEQb4QBxAnQCxgzkFkbf")
        XCTAssertEqual("972C432D04BC6908FA2825860148B8F911AC3D19C161C68E7A6B9BEAE86E05BA", scripthash)

        let scripthash1 = try RadiantAddressUtils().prepareScriptHash(address: "166w5AGDyvMkJqfDAtLbTJeoQh6FqYCfLQ")
        XCTAssertEqual("67809980FB38F7685D46A8108A39FE38956ADE259BE1C3E6FECBDEAA20FDECA9", scripthash1)
    }

    /// https://github.com/trustwallet/wallet-core/blob/master/tests/chains/Bitcoin/BitcoinAddressTests.cpp
    func testP2PKH_PrefixAddress() throws {
        let publicKey = Wallet.PublicKey(seedKey: Data(hexString: "039d645d2ce630c2a9a6dbe0cbd0a8fcb7b70241cb8a48424f25593290af2494b9"), derivationType: .none)
        let addressAdapter = BitcoinWalletCoreAddressAdapter(coin: .bitcoinCash)
        let adapterAddress = try addressAdapter.makeAddress(for: publicKey, by: .p2pkh)

        let legacyAddressService = BitcoinLegacyAddressService(networkParams: BitcoinCashNetworkParams())
        let legacyAddress = try legacyAddressService.makeAddress(from: publicKey.blockchainKey)

        XCTAssertEqual(adapterAddress.description, "12dNaXQtN5Asn2YFwT1cvciCrJa525fAe4")
        XCTAssertEqual(adapterAddress.description, legacyAddress.value)
    }

    /*
     https://radiantexplorer.com/tx/4190920ce863b70174e476d45c39b5b505dd244157a38dbaf3ce3c8794cd5789
     */
    func testSignRawTransaction() throws {
        let addressAdapter = BitcoinWalletCoreAddressAdapter(coin: .bitcoinCash)
        let address = try addressAdapter.makeAddress(
            for: Wallet.PublicKey(seedKey: publicKey.data, derivationType: .none),
            by: .p2pkh
        )

        XCTAssertEqual("166w5AGDyvMkJqfDAtLbTJeoQh6FqYCfLQ", address.description)

        let txBuilder = try RadiantTransactionBuilder(
            walletPublicKey: publicKey.data,
            decimalValue: blockchain.decimalValue
        )

        let utxo = [
            ElectrumUTXO(
                position: 1,
                hash: "4594c0fb5c5a8b4b2de2249fe704458e0e6e91e259258ca92d7c4e1067421e37",
                value: 68791375,
                height: 203208
            ),
            ElectrumUTXO(
                position: 0,
                hash: "2ae842e688ce5e74390de3e9a4754d3f7438266ab0526ff880b9188bb4ea0c28",
                value: 100000000,
                height: 203238
            ),
            ElectrumUTXO(
                position: 0,
                hash: "e2ea7fc29ca0dc4924f51f77918c8aff0c00fbb373a25509e928f78bf088cfcf",
                value: 10000000,
                height: 203428
            ),
            ElectrumUTXO(
                position: 0,
                hash: "aba3aefb04a43dc026adc35972e4a20f8bdacd48074c143372f1b99cfb6bf8bc",
                value: 10000000,
                height: 203439
            ),
            ElectrumUTXO(
                position: 0,
                hash: "ffaae960d8107cf4043dc32980c9634c9ff78fc69b2c6eb9b9c69a04a52ed179",
                value: 10000000,
                height: 203500
            ),
        ]

        txBuilder.update(utxo: utxo)

        let amounValueDecimal = Decimal(1000) / blockchain.decimalValue

        let amountValue = Amount(with: blockchain, value: amounValueDecimal)
        let feeValue = Amount(with: blockchain, value: .init(stringValue: "0.1")!)

        let transaction = Transaction(
            amount: amountValue,
            fee: Fee(feeValue),
            sourceAddress: address.description,
            destinationAddress: "1vr9gJkNzTHv8DEQb4QBxAnQCxgzkFkbf",
            changeAddress: address.description
        )

        let hashesForSign = try txBuilder.buildForSign(transaction: transaction)

        let expectedHashesForSign = ["DCC138199A41C63080CD88A1D4C1D9827FF9BF98A618C1C6B1AB8A38C528620E", "E32934BF77148D12F248A365030432C6A88498B986C48DF46AA06FF88A14A92D", "5B7D9FB8EE0847DAD0DEE814440838C9714B0520B3C00AA9244409EBF633ABDA", "82F61DAB8A2972533BBA775296ADCB4D1A2721FA9592661EA37DCF5ABCC2056E", "D885C2F51BFD7606C622AFEB850C6268C180537DB8B7993B53BEA0433A88CFCC"]

        XCTAssertEqual(hashesForSign.map { $0.hexString }, expectedHashesForSign)

        let expectedSignatures = ["4F7895FE109BB36400D6B77C7E766C84EC9E1D184DD2663C150EB21420DF93DA08CD71BC7F53C68C847B5D074A1832DA52E29F87EBD2DF0DDE86089301B4836100", "C6ED1C7D1A5CDA7D60EFDB598716720F11341793DEEFF478BDD2AA92CB679362653B661587EF323918DE860B59D6647991BEE2AE5875BF7C77E418234FFBF1CB01", "E0837B300AE20BAE4CF199A5A0C6DFA574A18E092838D67AFB0B073C1F87A552174FB80FF3043EF889FE0901DB6FA5C869051EE3543825A95E11E0657A9BBB9501", "F7D5EC299FC76BC53EAFDDC0B41A6C777302EB2B91CF910444E941440AB8401A0D502746F5D3AF1FA905BFF3024D51C32EA7A26F826BD96CFEF31302DE0152D900", "3CA565F1860B0191AA82DE6843F5E7A49511A3729AA9F18EB7D9A45F830E58A8056C2A15F0485E3DBAA331C56F2EDC7DAF35F793BF2829BB46338C32AD07B1F500"]

        XCTAssertEqual(expectedSignatures.count, hashesForSign.count)

        let signatures = expectedSignatures.map { Data(hexString: $0) }

        // Verify signature by public key
        if signatures.enumerated().contains(where: { index, sig in
            !publicKey.verify(signature: sig, message: Data(hashesForSign[index]))
        }) {
            throw WalletError.failedToBuildTx
        }

        let rawTransaction = try txBuilder.buildForSend(transaction: transaction, signatures: signatures)

        let expectedRawTransaction = "0100000005371e4267104e7c2da98c2559e2916e0e8e4504e79f24e22d4b8b5a5cfbc09445010000006a47304402204f7895fe109bb36400d6b77c7e766c84ec9e1d184dd2663c150eb21420df93da022008cd71bc7f53c68c847b5d074a1832da52e29f87ebd2df0dde86089301b48361412103d6fde463a4d0f4decc6ab11be24e83c55a15f68fd5db561eebca021976215ff5ffffffff280ceab48b18b980f86f52b06a2638743f4d75a4e9e30d39745ece88e642e82a000000006b483045022100c6ed1c7d1a5cda7d60efdb598716720f11341793deeff478bdd2aa92cb6793620220653b661587ef323918de860b59d6647991bee2ae5875bf7c77e418234ffbf1cb412103d6fde463a4d0f4decc6ab11be24e83c55a15f68fd5db561eebca021976215ff5ffffffffcfcf88f08bf728e90955a273b3fb000cff8a8c91771ff52449dca09cc27feae2000000006b483045022100e0837b300ae20bae4cf199a5a0c6dfa574a18e092838d67afb0b073c1f87a5520220174fb80ff3043ef889fe0901db6fa5c869051ee3543825a95e11e0657a9bbb95412103d6fde463a4d0f4decc6ab11be24e83c55a15f68fd5db561eebca021976215ff5ffffffffbcf86bfb9cb9f17233144c0748cdda8b0fa2e47259c3ad26c03da404fbaea3ab000000006b483045022100f7d5ec299fc76bc53eafddc0b41a6c777302eb2b91cf910444e941440ab8401a02200d502746f5d3af1fa905bff3024d51c32ea7a26f826bd96cfef31302de0152d9412103d6fde463a4d0f4decc6ab11be24e83c55a15f68fd5db561eebca021976215ff5ffffffff79d12ea5049ac6b9b96e2c9bc68ff79f4c63c98029c33d04f47c10d860e9aaff000000006a47304402203ca565f1860b0191aa82de6843f5e7a49511a3729aa9f18eb7d9a45f830e58a80220056c2a15f0485e3dbaa331c56f2edc7daf35f793bf2829bb46338c32ad07b1f5412103d6fde463a4d0f4decc6ab11be24e83c55a15f68fd5db561eebca021976215ff5ffffffff02e8030000000000001976a9140a2f12f228cbc244c745f33a23f7e924cbf3b6ad88ac67b6400b000000001976a91437f7d8745fb391f80384c4c375e6e884ee4cec2888ac00000000"

        XCTAssertEqual(rawTransaction.hexString.lowercased(), expectedRawTransaction)
    }
}
