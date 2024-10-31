//
//  KaspaTests.swift
//  BlockchainSdkTests
//
//  Created by Andrey Chukavin on 16.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import BitcoinCore
import TangemSdk
@testable import BlockchainSdk

class KaspaTests: XCTestCase {
    private let blockchain = Blockchain.kaspa(testnet: false)
    private let sizeTester = TransactionSizeTesterUtility()
    private var txBuilder: KaspaTransactionBuilder!

    override func setUp() {
        super.setUp()

        txBuilder = KaspaTransactionBuilder(walletPublicKey: .init(seedKey: Data(), derivationType: .none), blockchain: blockchain)
    }

    func testBuildSchnorrTransaction() {
        txBuilder.setUnspentOutputs([
            BlockchainSdk.BitcoinUnspentOutput(
                transactionHash: "deb88e7dd734437c6232a636085ef917d1d13cc549fe14749765508b2782f2fb",
                outputIndex: 0,
                amount: 10000000,
                outputScript: "21034c88a1a83469ddf20d0c07e5c4a1e7b83734e721e60d642b94a53222c47c670dab"
            ),
            BlockchainSdk.BitcoinUnspentOutput(
                transactionHash: "304db39069dc409acedf544443dcd4a4f02bfad4aeb67116f8bf087822c456af",
                outputIndex: 0,
                amount: 10000000,
                outputScript: "21034c88a1a83469ddf20d0c07e5c4a1e7b83734e721e60d642b94a53222c47c670dab"
            ),
            BlockchainSdk.BitcoinUnspentOutput(
                transactionHash: "ae96e819429e9da538e84cb213f62fbc8ad32e932d7c7f1fb9bd2fedf8fd7b4a",
                outputIndex: 0,
                amount: 500000000,
                outputScript: "21034c88a1a83469ddf20d0c07e5c4a1e7b83734e721e60d642b94a53222c47c670dab"
            ),
        ])

        let walletPublicKey = "04EB30400CE9D1DEED12B84D4161A1FA922EF4185A155EF3EC208078B3807B126FA22C335081AAEBF161095C11C7D8BD550EF8882A3125B0EE9AE96DDDE1AE743F"
        let sourceAddress = try! KaspaAddressService(isTestnet: false).makeAddress(from: Data(hex: walletPublicKey))
        let destination = "kaspa:qpsqw2aamda868dlgqczeczd28d5nc3rlrj3t87vu9q58l2tugpjs2psdm4fv"

        let transaction = Transaction(
            amount: Amount(with: blockchain, value: 0.001),
            fee: Fee(Amount(with: blockchain, value: 0.000300000000001)), // otherwise the tests fail, can't convert to 0.0003 properly
            sourceAddress: sourceAddress.value,
            destinationAddress: destination,
            changeAddress: sourceAddress.value
        )

        let (kaspaTransaction, hashes) = try! txBuilder.buildForSign(transaction)

        let expectedHashes = [
            Data(hex: "F5080102132C6DAB382DE67A427F1DF560BA7F5F0D7FA4DFA535C474761423C2"),
            Data(hex: "90767E75D102556256E4B3C76F341292FDDBEF1683C49E3C03AC16A83FD1FB83"),
            Data(hex: "F9738FE93426667581DB4BA1AE4F432F384C393D0F098D3A9AA6087C4F62C4A4"),
        ]
        XCTAssertEqual(hashes, expectedHashes)

        let signatures = [
            Data(hexString: "E2747D4E00C55D69FA0B8ADFAFD07F41144F888E322D377878E83F25FD2E258B2E918EF79E151337D7F3BD0798D66FDCE04B07C30984424B13344F0A7CC40165"),
            Data(hexString: "4BF71C43DF96FC6B46766CAE30E97BD9018E9B98BB2C3645744A696AD26ECC780157EA9D44DC41D0BCB420175A5D3F543079F4263AA2DBDE0EE2D33A877FC583"),
            Data(hexString: "E2747D4E00C55D69FA0B8ADFAFD07F41144F888E322D377878E83F25FD2E258B2E918EF79E151337D7F3BD0798D66FDCE04B07C30984424B13344F0A7CC40168"),
        ]

        let builtTransaction = txBuilder.buildForSend(transaction: kaspaTransaction, signatures: signatures)

        let expectedTransaction = KaspaTransactionData(
            inputs: [
                BlockchainSdk.KaspaInput(
                    previousOutpoint: BlockchainSdk.KaspaPreviousOutpoint(
                        transactionId: "ae96e819429e9da538e84cb213f62fbc8ad32e932d7c7f1fb9bd2fedf8fd7b4a",
                        index: 0
                    ),
                    signatureScript: "41e2747d4e00c55d69fa0b8adfafd07f41144f888e322d377878e83f25fd2e258b2e918ef79e151337d7f3bd0798d66fdce04b07c30984424b13344f0a7cc4016501"
                ),
                BlockchainSdk.KaspaInput(
                    previousOutpoint: BlockchainSdk.KaspaPreviousOutpoint(
                        transactionId: "deb88e7dd734437c6232a636085ef917d1d13cc549fe14749765508b2782f2fb",
                        index: 0
                    ),
                    signatureScript: "414bf71c43df96fc6b46766cae30e97bd9018e9b98bb2c3645744a696ad26ecc780157ea9d44dc41d0bcb420175a5d3f543079f4263aa2dbde0ee2d33a877fc58301"
                ),
                BlockchainSdk.KaspaInput(
                    previousOutpoint: BlockchainSdk.KaspaPreviousOutpoint(
                        transactionId: "304db39069dc409acedf544443dcd4a4f02bfad4aeb67116f8bf087822c456af",
                        index: 0
                    ),
                    signatureScript: "41e2747d4e00c55d69fa0b8adfafd07f41144f888e322d377878e83f25fd2e258b2e918ef79e151337d7f3bd0798d66fdce04b07c30984424b13344f0a7cc4016801"
                ),
            ],
            outputs: [
                BlockchainSdk.KaspaOutput(
                    amount: 100000,
                    scriptPublicKey: BlockchainSdk.KaspaScriptPublicKey(
                        scriptPublicKey: "2060072bbddb7a7d1dbf40302ce04d51db49e223f8e5159fcce14143fd4be20328ac"
                    )
                ),
                BlockchainSdk.KaspaOutput(
                    amount: 519870000,
                    scriptPublicKey: BlockchainSdk.KaspaScriptPublicKey(
                        scriptPublicKey: "2103eb30400ce9d1deed12b84d4161a1fa922ef4185a155ef3ec208078b3807b126fab"
                    )
                ),
            ]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let encodedBuiltTransaction = try! encoder.encode(builtTransaction)
        let encodedExpectedTransaction = try! encoder.encode(expectedTransaction)
        XCTAssertEqual(encodedBuiltTransaction, encodedExpectedTransaction)
    }

    func testP2SHTransaction() {
        txBuilder.setUnspentOutputs([
            BlockchainSdk.BitcoinUnspentOutput(
                transactionHash: "ae96e819429e9da538e84cb213f62fbc8ad32e932d7c7f1fb9bd2fedf8fd7b4a",
                outputIndex: 0,
                amount: 500000000,
                outputScript: "21034c88a1a83469ddf20d0c07e5c4a1e7b83734e721e60d642b94a53222c47c670dab"
            ),
        ])

        let walletPublicKey = "04EB30400CE9D1DEED12B84D4161A1FA922EF4185A155EF3EC208078B3807B126FA22C335081AAEBF161095C11C7D8BD550EF8882A3125B0EE9AE96DDDE1AE743F"
        let sourceAddress = try! KaspaAddressService(isTestnet: false).makeAddress(from: Data(hex: walletPublicKey))
        let destination = "kaspa:pqurku73qluhxrmvyj799yeyptpmsflpnc8pha80z6zjh6efwg3v2rrepjm5r"

        let transaction = Transaction(
            amount: Amount(with: blockchain, value: 0.001),
            fee: Fee(Amount(with: blockchain, value: 0.0001)),
            sourceAddress: sourceAddress.value,
            destinationAddress: destination,
            changeAddress: sourceAddress.value
        )

        let (kaspaTransaction, hashes) = try! txBuilder.buildForSign(transaction)

        let expectedHashes = [
            Data(hex: "C550515D34A091D7F3D2827286E7AEF685ECE9C0BBCCB4B08BC65F6EBD83E8F2"),
        ]
        XCTAssertEqual(hashes, expectedHashes)

        let signatures = [
            Data(hexString: "E2747D4E00C55D69FA0B8ADFAFD07F41144F888E322D377878E83F25FD2E258B2E918EF79E151337D7F3BD0798D66FDCE04B0704EB30400CE9D1DEED12B84D41"),
        ]

        let builtTransaction = txBuilder.buildForSend(transaction: kaspaTransaction, signatures: signatures)

        let expectedTransaction = KaspaTransactionData(
            inputs: [
                BlockchainSdk.KaspaInput(
                    previousOutpoint: BlockchainSdk.KaspaPreviousOutpoint(
                        transactionId: "ae96e819429e9da538e84cb213f62fbc8ad32e932d7c7f1fb9bd2fedf8fd7b4a",
                        index: 0
                    ),
                    signatureScript: "41e2747d4e00c55d69fa0b8adfafd07f41144f888e322d377878e83f25fd2e258b2e918ef79e151337d7f3bd0798d66fdce04b0704eb30400ce9d1deed12b84d4101"
                ),
            ],
            outputs: [
                BlockchainSdk.KaspaOutput(
                    amount: 100000,
                    scriptPublicKey: BlockchainSdk.KaspaScriptPublicKey(
                        scriptPublicKey: "aa20383b73d107f9730f6c24bc5293240ac3b827e19e0e1bf4ef16852beb297222c587"
                    )
                ),
                BlockchainSdk.KaspaOutput(
                    amount: 499890000,
                    scriptPublicKey: BlockchainSdk.KaspaScriptPublicKey(
                        scriptPublicKey: "2103eb30400ce9d1deed12b84d4161a1fa922ef4185a155ef3ec208078b3807b126fab"
                    )
                ),
            ]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let encodedBuiltTransaction = try! encoder.encode(builtTransaction)
        let encodedExpectedTransaction = try! encoder.encode(expectedTransaction)
        XCTAssertEqual(encodedBuiltTransaction, encodedExpectedTransaction)
    }

    func testTransactionHash() {
        let tx1 = KaspaTransaction(
            inputs: [
                BitcoinUnspentOutput(
                    transactionHash: "4df1f7923708f6fa98f8d192cdb511666fc93c858d86fb7bc61bc7c13d54c9f4",
                    outputIndex: 2,
                    amount: 0, // not used
                    outputScript: "415bfc0dde408a06ec6a39ae850986b49c2d0d5b83e47233b43012de3aedcecde75ebc239008060bd50633e8e1aeba891300ca74e8279dd591d8ceda60609afa6001"
                ),
            ],
            outputs: [
                KaspaOutput(
                    amount: UInt64(500003000),
                    scriptPublicKey: .init(scriptPublicKey: "aa207b1cfee1aa9cb2ab4eff9ff9593f88d3f0453f02e02790ac493f8eb712dce17787", version: 0)
                ),
                KaspaOutput(
                    amount: UInt64(3764387352),
                    scriptPublicKey: .init(scriptPublicKey: "2035c82aa416591a1afb84d10b6d225899f27ce6b51381c03b8cf104c3906258d3ac", version: 0)
                ),
            ]
        )

        let tx2 = KaspaTransaction(
            inputs: [
                BitcoinUnspentOutput(
                    transactionHash: "03f30878b05fdfd6c47f749538f77629fd5e48c93233c36e737493caf6c67915",
                    outputIndex: 0,
                    amount: 0, // not used
                    outputScript: "412fe34c676f75602942c9e63dc554e2f8abe4929436e8debf0cc5bd2efde012541afa6a300867742728390c73e0ac39b4778c314734f92806f9d236fa1c48f94301"
                ),
                BitcoinUnspentOutput(
                    transactionHash: "c69a424df624c9c235f23afc0ce20afbfd56ea042f3123e9c464ffb8b2b2f33c",
                    outputIndex: 0,
                    amount: 0, // not used
                    outputScript: "41596c4bb99592c5637accfaf9e3793b934ece1402e267f8d1e309d73cd5139c544305662442fdfe298bfd65bd884199ec83482f801bbc3dee76903ca5187b6deb01"
                ),
                BitcoinUnspentOutput(
                    transactionHash: "2958f73001b95a36d8e51697fcb6d842b6068f49e9e46a73550e35527a40d878",
                    outputIndex: 0,
                    amount: 0, // not used
                    outputScript: "414c35049eb692e2596c00541fb0812cd3a05a11b6cc368476272702295ba8252b27c077c4a256a30979d27d21d0ea99139581d0646c1162ec52535d2568c8995301"
                ),
                BitcoinUnspentOutput(
                    transactionHash: "705624bb67706ddc1351868ee19d7642262810cd072acbf0b08fed6050283079",
                    outputIndex: 0,
                    amount: 0, // not used
                    outputScript: "41de193ea21790d577bdbb29574cbfaf6444459e42de711cb60156f459ee725edb4fc223518ea77c60bc637256e1597e9681565d01f08195f8a8d071caee0d786301"
                ),
                BitcoinUnspentOutput(
                    transactionHash: "7b5035caf767c7173915bfb880031e7222b1affa175343a9ca2a924e314a226d",
                    outputIndex: 0,
                    amount: 0, // not used
                    outputScript: "41061dcffbbaedb3a03cd15b73677d7da8292f489c833b06ca7c77e6256173782e60e1b360a8f3c20e7a445ac0e63830295045c111571ef55635879f2b50493c0901"
                ),
            ],
            outputs: [
                KaspaOutput(
                    amount: UInt64(57103393833),
                    scriptPublicKey: .init(scriptPublicKey: "2035c82aa416591a1afb84d10b6d225899f27ce6b51381c03b8cf104c3906258d3ac", version: 0)
                ),
            ]
        )

        XCTAssertEqual(tx1.transactionId?.hexadecimal, "c2cb9d865f5085cd6f7f23365545c68d1eaca7e3cde9d231a64812be2c989a30")
        XCTAssertEqual(tx1.transactionHash?.hexadecimal, "06661f542544b166259af2e5dd01fc873a8893bf1aa4fada36fb92dfce64b4b0")
        XCTAssertEqual(tx2.transactionId?.hexadecimal, "d9cd38d294de5cce401330a91c97807b5433a377e043e99b66363fe5274477c9")
        XCTAssertEqual(tx2.transactionHash?.hexadecimal, "b5b1f2be9ec7dd34ee0da90addcae9bb7bbba145b1460ad639017059f9e41829")
    }
}
