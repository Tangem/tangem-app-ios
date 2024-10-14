//
//  StellarTests.swift
//  BlockchainSdkTests
//
//  Created by Andrew Son on 04/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import XCTest
import stellarsdk
import Combine

@testable import BlockchainSdk

class StellarTests: XCTestCase {
    private let sizeTester = TransactionSizeTesterUtility()
    
    private lazy var addressService = StellarAddressService()
    private var bag = Set<AnyCancellable>()
    
    override func setUp() {
        super.setUp()
        bag = []
    }
    
    func testAddress() {
        let walletPubkey = Data(hex: "EC5387D8B38BD9EF80BDBC78D0D7E1C53F08E269436C99D5B3C2DF4B2CE73012")
        let expectedAddress = "GDWFHB6YWOF5T34AXW6HRUGX4HCT6CHCNFBWZGOVWPBN6SZM44YBFUDZ"
        
        XCTAssertEqual(try! addressService.makeAddress(from: walletPubkey).value, expectedAddress)
    }
    
    func testValidateCorrectAddress() {
        XCTAssertFalse(addressService.validate("GDWFc"))
        XCTAssertFalse(addressService.validate("GDWFHядыфлвФЫВЗФЫВЛ++EÈ"))
        XCTAssertTrue(addressService.validate("GDWFHB6YWOF5T34AXW6HRUGX4HCT6CHCNFBWZGOVWPBN6SZM44YBFUDZ"))
    }
    
    func testCorrectCoinTransactionEd25519() {
        testCorrectCoinTransaction(blockchain: .stellar(curve: .ed25519, testnet: false))
    }
    
    func testCorrectCoinTransactionEd25519Slip0010() {
        testCorrectCoinTransaction(blockchain: .stellar(curve: .ed25519_slip0010, testnet: false))
    }
    
    func testCorrectCoinTransaction(blockchain: Blockchain) {
        let walletPubkey = Data(hex: "9FE5BB2CC7D83C1DA10845AFD8A34B141FD8FD72500B95B1547E12B9BB8AAC3D")
        let signature = Data(hex: "EA1908DD1B2B0937758E5EFFF18DB583E41DD47199F575C2D83B354E29BF439C850DC728B9D0B166F6F7ACD160041EE3332DAD04DD08904CB0D2292C1A9FB802")
        
        let sendValue = Decimal(0.1)
        let feeValue = Decimal(0.00001)
        let destinationAddress = "GBPMXXLHHPCOO4YOWGS4BWSVMLELZ355DVQ6JCGZX3H4HO3LH2SUETUW"
        
        let walletAddress = try! addressService.makeAddress(from: walletPubkey)
        
        let txBuilder = StellarTransactionBuilder(walletPublicKey: walletPubkey, isTestnet: false)
        txBuilder.sequence = 139655650517975046
        txBuilder.specificTxTime = 1614848128.2697558
        
        let amountToSend = Amount(with: blockchain, type: .coin, value: sendValue)
        let feeAmount = Amount(with: blockchain, type: .coin, value: feeValue)
        let fee = Fee(feeAmount)
        let tx = Transaction(amount: amountToSend,
                             fee: fee,
                             sourceAddress: walletAddress.value,
                             destinationAddress: destinationAddress,
                             changeAddress: walletAddress.value)
        
        let expectedHashToSign = Data(hex: "499fd7cd87e57c291c9e66afaf652a1e74f560cce45b5c9388bd801effdb468f")
        let expectedSignedTx = "AAAAAgAAAACf5bssx9g8HaEIRa/Yo0sUH9j9clALlbFUfhK5u4qsPQAAAGQB8CgTAAAABwAAAAEAAAAAYECf6gAAAABgQKEWAAAAAQAAAAAAAAABAAAAAQAAAACf5bssx9g8HaEIRa/Yo0sUH9j9clALlbFUfhK5u4qsPQAAAAEAAAAAXsvdZzvE53MOsaXA2lViyLzvvR1h5IjZvs/Du2s+pUIAAAAAAAAAAAAPQkAAAAAAAAAAAbuKrD0AAABA6hkI3RsrCTd1jl7/8Y21g+Qd1HGZ9XXC2Ds1Tim/Q5yFDccoudCxZvb3rNFgBB7jMy2tBN0IkEyw0iksGp+4Ag=="
        
        let expectations = expectation(description: "All values received")
        
        let targetAccountResponse = StellarTargetAccountResponse(accountCreated: true, trustlineCreated: true)
        txBuilder.buildForSign(targetAccountResponse: targetAccountResponse, transaction: tx)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    XCTFail("Failed to build tx. Reason: \(error.localizedDescription)")
                }
            }, receiveValue: { (hash, txData) in
                XCTAssertEqual(hash, expectedHashToSign)
                
                self.sizeTester.testTxSize(hash)
                guard let signedTx = txBuilder.buildForSend(signature: signature, transaction: txData) else {
                    XCTFail("Failed to build tx for send")
                    return
                }
                
                XCTAssertEqual(signedTx, expectedSignedTx)
                
                expectations.fulfill()
                return
            })
            .store(in: &bag)
        waitForExpectations(timeout: 5, handler: nil)
    }
}
