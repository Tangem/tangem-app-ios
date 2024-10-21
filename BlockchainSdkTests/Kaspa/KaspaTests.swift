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
        
        self.txBuilder = KaspaTransactionBuilder(blockchain: blockchain)
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
                )
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
                )
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
                )
            ]
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let encodedBuiltTransaction = try! encoder.encode(builtTransaction)
        let encodedExpectedTransaction = try! encoder.encode(expectedTransaction)
        XCTAssertEqual(encodedBuiltTransaction, encodedExpectedTransaction)
    }
}
