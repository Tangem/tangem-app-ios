//
//  SmartContractMethodTests.swift
//  BlockchainSdkTests
//
//  Created by Sergey Balashov on 18.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import BigInt

@testable import BlockchainSdk

final class SmartContractMethodTests: XCTestCase {
    func testTransferERC20TokenMethod() throws {
        // give
        let destination = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"
        let amount = BigUInt("1000000")
        
        // when
        let data = TransferERC20TokenMethod(destination: destination, amount: amount).data
        
        // then
        let expectedData = [
            "a9059cbb",
            "00000000000000000000000090e4d59c8583e37426b37d1d7394b6008a987c67",
            "00000000000000000000000000000000000000000000000000000000000f4240"
        ]
        
        XCTAssertEqual(data.hexString.lowercased(), expectedData.joined().lowercased())
    }
    
    func testApproveERC20TokenMethod() throws {
        // give
        let spender = "0x1111111254EEB25477B68fb85Ed929f73A960582"
        let amount = BigUInt("1000000")
        
        // when
        let data = ApproveERC20TokenMethod(spender: spender, amount: amount).data
        
        // then
        let expectedData = [
            "095ea7b3",
            "0000000000000000000000001111111254EEB25477B68fb85Ed929f73A960582",
            "00000000000000000000000000000000000000000000000000000000000f4240"
        ]
        
        XCTAssertEqual(data.hexString.lowercased(), expectedData.joined().lowercased())
    }
    
    func testAllowanceERC20TokenMethod() throws {
        // give
        let owner = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"
        let spender = "0x1111111254EEB25477B68fb85Ed929f73A960582"
        
        // when
        let data = AllowanceERC20TokenMethod(owner: owner, spender: spender).data
        
        // then
        let expectedData = [
            "dd62ed3e",
            "00000000000000000000000090e4d59c8583e37426b37d1d7394b6008a987c67",
            "0000000000000000000000001111111254EEB25477B68fb85Ed929f73A960582"
        ]
        
        XCTAssertEqual(data.hexString.lowercased(), expectedData.joined().lowercased())
    }
    
    func testTokenBalanceERC20TokenMethod() throws {
        // give
        let owner = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"
        
        // when
        let data = TokenBalanceERC20TokenMethod(owner: owner).data
        
        // then
        let expectedData = [
            "70a08231",
            "00000000000000000000000090e4d59c8583e37426b37d1d7394b6008a987c67"
        ]
        
        XCTAssertEqual(data.hexString.lowercased(), expectedData.joined().lowercased())
    }
    
    
}
