//
//  TronTests.swift
//  BlockchainSdkTests
//
//  Created by Andrey Chukavin on 27.04.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import XCTest

@testable import BlockchainSdk

class TronTests: XCTestCase {
    var blockchain: Blockchain!
    var txBuilder: TronTransactionBuilder!
    
    let tronBlock = TronBlock(
        block_header: .init(
            raw_data: .init(
                number: 3111739,
                txTrieRoot: "64288c2db0641316762a99dbb02ef7c90f968b60f9f2e410835980614332f86d",
                witness_address: "415863f6091b8e71766da808b1dd3159790f61de7d",
                parentHash: "00000000002f7b3af4f5f8b9e23a30c530f719f165b742e7358536b280eead2d",
                version: 3,
                timestamp: 1539295479000
            )
        )
    )
    
    override func setUp() {
        self.blockchain = Blockchain.tron(testnet: true)
        self.txBuilder = TronTransactionBuilder()
    }
    
    func testTrxTransfer() throws {
        let transaction = Transaction(
            amount: Amount(with: blockchain, value: 1),
            fee: Fee(.zeroCoin(for: blockchain)),
            sourceAddress: "TU1BRXbr6EmKmrLL4Kymv7Wp18eYFkRfAF",
            destinationAddress: "TXXxc9NsHndfQ2z9kMKyWpYa5T3QbhKGwn",
            changeAddress: "TU1BRXbr6EmKmrLL4Kymv7Wp18eYFkRfAF"
        )

        let presignedInput = try txBuilder.buildForSign(transaction: transaction, block: tronBlock)
        let signature = Data(hex: "6b5de85a80b2f4f02351f691593fb0e49f14c5cb42451373485357e42d7890cd77ad7bfcb733555c098b992da79dabe5050f5e2db77d9d98f199074222de037701")
        let transactionData = try txBuilder.buildForSend(rawData: presignedInput.rawData, signature: signature)
        
        let expectedTransactionData = Data(hex: "0a85010a027b3b2208b21ace8d6ac20e7e40d8abb9bae62c5a67080112630a2d747970652e676f6f676c65617069732e636f6d2f70726f746f636f6c2e5472616e73666572436f6e747261637412320a1541c5d1c75825b30bb2e2e655798209d56448eb6b5e121541ec8c5a0fcbb28f14418eed9cf582af0d77e4256e18c0843d70d889a4a9e62c12416b5de85a80b2f4f02351f691593fb0e49f14c5cb42451373485357e42d7890cd77ad7bfcb733555c098b992da79dabe5050f5e2db77d9d98f199074222de037701")
        
        XCTAssertEqual(transactionData, expectedTransactionData)
    }
    
    func testTrc20TransferUSDT() throws {
        let token = Token(name: "Tether",
                          symbol: "USDT",
                          contractAddress: "TXLAQ63Xg1NAzckPwKHvzw7CSEmLMEqcdj",
                          decimalCount: 6)
        
        let amountValues: [Decimal] = [
            1,
            1000000000000000000,
        ]
        
        let transactionDataList = try amountValues.map { amountValue -> Data in

            let transaction = Transaction(
                amount: Amount(with: token, value: amountValue),
                fee: Fee(.zeroCoin(for: blockchain)),
                sourceAddress: "TU1BRXbr6EmKmrLL4Kymv7Wp18eYFkRfAF",
                destinationAddress: "TXXxc9NsHndfQ2z9kMKyWpYa5T3QbhKGwn",
                changeAddress: "TU1BRXbr6EmKmrLL4Kymv7Wp18eYFkRfAF"
            )

            let presignedInput = try txBuilder.buildForSign(transaction: transaction, block: tronBlock)
            let signature = Data(hex: "6b5de85a80b2f4f02351f691593fb0e49f14c5cb42451373485357e42d7890cd77ad7bfcb733555c098b992da79dabe5050f5e2db77d9d98f199074222de037701")
            let transactionData = try txBuilder.buildForSend(rawData: presignedInput.rawData, signature: signature)

            return transactionData
        }
        
        
        
        let expectedTransactionDataList = [
            Data(hex: "0ad3010a027b3b2208b21ace8d6ac20e7e40d8abb9bae62c5aae01081f12a9010a31747970652e676f6f676c65617069732e636f6d2f70726f746f636f6c2e54726967676572536d617274436f6e747261637412740a1541c5d1c75825b30bb2e2e655798209d56448eb6b5e121541ea51342dabbb928ae1e576bd39eff8aaf070a8c62244a9059cbb000000000000000000000041ec8c5a0fcbb28f14418eed9cf582af0d77e4256e00000000000000000000000000000000000000000000000000000000000f424070d889a4a9e62c900180c2d72f12416b5de85a80b2f4f02351f691593fb0e49f14c5cb42451373485357e42d7890cd77ad7bfcb733555c098b992da79dabe5050f5e2db77d9d98f199074222de037701"),
            Data(hex: "0ad3010a027b3b2208b21ace8d6ac20e7e40d8abb9bae62c5aae01081f12a9010a31747970652e676f6f676c65617069732e636f6d2f70726f746f636f6c2e54726967676572536d617274436f6e747261637412740a1541c5d1c75825b30bb2e2e655798209d56448eb6b5e121541ea51342dabbb928ae1e576bd39eff8aaf070a8c62244a9059cbb000000000000000000000041ec8c5a0fcbb28f14418eed9cf582af0d77e4256e00000000000000000000000000000000000000000000d3c21bcecceda100000070d889a4a9e62c900180c2d72f12416b5de85a80b2f4f02351f691593fb0e49f14c5cb42451373485357e42d7890cd77ad7bfcb733555c098b992da79dabe5050f5e2db77d9d98f199074222de037701"),
        ]
        
        XCTAssertEqual(transactionDataList, expectedTransactionDataList)
    }
    
    func testTrc20TransferJST() throws {
        let token = Token(name: "JST",
                          symbol: "JST",
                          contractAddress: "TF17BgPaZYbz8oxbjhriubPDsA7ArKoLX3",
                          decimalCount: 18)
        
        // Parsing strings because Double literals will lose precision
        let amountValues: [Decimal] = [
            Decimal(string: "123456789123456789.123456789123456789")!,
            Decimal(string: "123456789123456789.123456789")!,
        ]
        
        let transactionDataList = try amountValues.map { amountValue -> Data in

            let transaction = Transaction(
                amount: Amount(with: token, value: amountValue),
                fee: Fee(.zeroCoin(for: blockchain)),
                sourceAddress: "TU1BRXbr6EmKmrLL4Kymv7Wp18eYFkRfAF",
                destinationAddress: "TXXxc9NsHndfQ2z9kMKyWpYa5T3QbhKGwn",
                changeAddress: "TU1BRXbr6EmKmrLL4Kymv7Wp18eYFkRfAF"
            )

            let presignedInput = try txBuilder.buildForSign(transaction: transaction, block: tronBlock)
            let signature = Data(hex: "6b5de85a80b2f4f02351f691593fb0e49f14c5cb42451373485357e42d7890cd77ad7bfcb733555c098b992da79dabe5050f5e2db77d9d98f199074222de037701")
            let transactionData = try txBuilder.buildForSend(rawData: presignedInput.rawData, signature: signature)

            return transactionData
        }
        
        let expectedTransactionDataList = [
            Data(hex: "0ad3010a027b3b2208b21ace8d6ac20e7e40d8abb9bae62c5aae01081f12a9010a31747970652e676f6f676c65617069732e636f6d2f70726f746f636f6c2e54726967676572536d617274436f6e747261637412740a1541c5d1c75825b30bb2e2e655798209d56448eb6b5e12154137349aeb75a32f8c4c090daff376cf975f5d2eba2244a9059cbb000000000000000000000041ec8c5a0fcbb28f14418eed9cf582af0d77e4256e000000000000000000000000000000000017c6e3c032f89045ad746684045f1570d889a4a9e62c900180c2d72f12416b5de85a80b2f4f02351f691593fb0e49f14c5cb42451373485357e42d7890cd77ad7bfcb733555c098b992da79dabe5050f5e2db77d9d98f199074222de037701"),
            Data(hex: "0ad3010a027b3b2208b21ace8d6ac20e7e40d8abb9bae62c5aae01081f12a9010a31747970652e676f6f676c65617069732e636f6d2f70726f746f636f6c2e54726967676572536d617274436f6e747261637412740a1541c5d1c75825b30bb2e2e655798209d56448eb6b5e12154137349aeb75a32f8c4c090daff376cf975f5d2eba2244a9059cbb000000000000000000000041ec8c5a0fcbb28f14418eed9cf582af0d77e4256e000000000000000000000000000000000017c6e3c032f89045ad74667ca8920070d889a4a9e62c900180c2d72f12416b5de85a80b2f4f02351f691593fb0e49f14c5cb42451373485357e42d7890cd77ad7bfcb733555c098b992da79dabe5050f5e2db77d9d98f199074222de037701"),
        ]
        
        XCTAssertEqual(transactionDataList, expectedTransactionDataList)
    }
    
    func testBalanceResponse() throws {
        let longConstantResult = "0000000000000000000000000000000000000000000000001e755ae3061df48700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
        
        let shortConstantResult = "0000000000000000000000000000000000000000000000000000000001e835f8"
        
        let utils = TronUtils()
        
        try XCTAssertEqual(utils.parseBalance(response: [longConstantResult], decimals: 0), Decimal(stringValue: "2194760324519687303"))
        try XCTAssertEqual(utils.parseBalance(response: [shortConstantResult], decimals: 0), Decimal(stringValue: "31995384"))
    }
}
