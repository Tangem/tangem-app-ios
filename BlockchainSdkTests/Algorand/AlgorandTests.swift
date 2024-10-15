//
//  AlgorandTests.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 28.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import XCTest
import WalletCore

@testable import BlockchainSdk

final class AlgorandTests: XCTestCase {
    private let coinType: CoinType = .algorand
    
    /*
     - Use private key for Algorand coin at test mnemonic
     - tiny escape drive pupil flavor endless love walk gadget match filter luxury
     - Address for coin EH5I3KCDCTB4AOML3E4W5BIGQMPA7GT5Q3PUMK3AIXNFYQHMX5KOJBOJRM
     */
    private let privateKeyData = Data(hexString: "F3903F329F8F52BCA0F92ACD127A3EC9A939028951D6EBAB72DD22C966EADFAB")
    
    // MARK: - Impementation
    
    func testCorrectTransactionEd25519() throws {
        try testTransactionBuilder(curve: .ed25519)
    }
    
    func testCorrectTransactionEd25519Slip0010() throws {
        try testTransactionBuilder(curve: .ed25519_slip0010)
    }
    
    /*
     https://algoexplorer.io/tx/GMS3DRWDCL3SC57BCKCTOBV2SBIZZMTHNYEUZEV6A6WWH4DOS6TQ
     */
    func testTransactionBuilder(curve: EllipticCurve) throws {
        let blockchain: BlockchainSdk.Blockchain = .algorand(curve: curve, testnet: false)
        
        let privateKey = PrivateKey(data: privateKeyData)!
        let publicKey = privateKey.getPublicKeyByType(pubkeyType: .ed25519)
        
        let transactionBuilder = AlgorandTransactionBuilder(
            publicKey: publicKey.data,
            curve: .ed25519_slip0010,
            isTestnet: blockchain.isTestnet
        )
        
        let amount = Amount(with: blockchain, value: 500000 / blockchain.decimalValue)
        let fee = Fee(Amount(with: blockchain, value: 1000 / blockchain.decimalValue))
        
        let transaction = Transaction(
            amount: amount,
            fee: fee,
            sourceAddress: "EH5I3KCDCTB4AOML3E4W5BIGQMPA7GT5Q3PUMK3AIXNFYQHMX5KOJBOJRM",
            destinationAddress: "ZT5PY4SU4LCUV52U5THWA4NMPJCNBU2PDG7B4YFVMC3UKZJQQGUZIM7PKM",
            changeAddress: ""
        )
        
        let round: UInt64 = 35626367
        
        let buildParameters = AlgorandTransactionBuildParams(
            genesisId: "mainnet-v1.0",
            genesisHash: Data(base64Encoded: "wGHE2Pwdvd7S12BL5FaOP20EGYesN73ktiC1qzkkit8=")!,
            firstRound: round,
            lastRound: round + 1000
        )
        
        let buildForSign = try transactionBuilder.buildForSign(
            transaction: transaction,
            with: buildParameters
        )
        
        let expectedBuildForSign = "545889A3616D74CE0007A120A3666565CD03E8A26676CE021F9D7FA367656EAC6D61696E6E65742D76312E30A26768C420C061C4D8FC1DBDDED2D7604BE4568E3F6D041987AC37BDE4B620B5AB39248ADFA26C76CE021FA167A3726376C420CCFAFC7254E2C54AF754ECCF6071AC7A44D0D34F19BE1E60B560B745653081A9A3736E64C42021FA8DA84314C3C0398BD9396E8506831E0F9A7D86DF462B6045DA5C40ECBF54A474797065A3706179"
        
        XCTAssertEqual(buildForSign.hexString, expectedBuildForSign)
        
        let signature = privateKey.sign(digest: buildForSign, curve: .ed25519)
        XCTAssertNotNil(signature)
        
        // Validate hash size
        TransactionSizeTesterUtility().testTxSizes([signature ?? Data()])
        
        let buildForSend = try transactionBuilder.buildForSend(
            transaction: transaction,
            with: buildParameters,
            signature: signature!
        )
        
        let exexpectedBuildForSend = "82A3736967C4405439E70F1BF1236C2E8E7CB883CD7B44331A92C2724DE6D99F45E23894C56291A3A87DCA55895563717F28B6EB06C3963CB37A9CE60CE597F59986763284E40CA374786E89A3616D74CE0007A120A3666565CD03E8A26676CE021F9D7FA367656EAC6D61696E6E65742D76312E30A26768C420C061C4D8FC1DBDDED2D7604BE4568E3F6D041987AC37BDE4B620B5AB39248ADFA26C76CE021FA167A3726376C420CCFAFC7254E2C54AF754ECCF6071AC7A44D0D34F19BE1E60B560B745653081A9A3736E64C42021FA8DA84314C3C0398BD9396E8506831E0F9A7D86DF462B6045DA5C40ECBF54A474797065A3706179"
        
        XCTAssertEqual(buildForSend.hexString, exexpectedBuildForSend)
    }
    
}
