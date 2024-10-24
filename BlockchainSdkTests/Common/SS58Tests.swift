//
//  SS58Tests.swift
//  BlockchainSdkTests
//
//  Created by Dmitry Fedorov on 26.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import XCTest
@testable import BlockchainSdk

// Hardcoded addresses provided via 'subkey' command line tool
// either 'subkey generate -n <network>'
// or 'subkey inspect --public <hex address> -n <network>'
final class SS58Tests: XCTestCase {
    private let ss58 = SS58()
    
    func testPublicKeyIsLessOrEqualThan32Bytes() {
        let data1 = Data(hex: "0x1")
        let addressData1 = ss58.accountData(from: data1)
        
        XCTAssertEqual(data1, addressData1)
        
        let data2 = Data(hex: "0xB7D152D0703FAD867AFCB9F6E12F223C88A7592BF640547A620CFFAA91E0D06E") // 32-byte
        let addressData2 = ss58.accountData(from: data2)
        
        XCTAssertEqual(data2, addressData2)
    }
    
    func testPublicKeyIsGreaterThan32Bytes() {
        let data = Data(hex: "0x215AF345DBE3C884B6CC7C96F906731393515E3B2DC9FB28D7C896369AB930ADA1") // 33-byte
        
        let addressData = ss58.accountData(from: data)
        
        XCTAssertNotNil(addressData)
        XCTAssertNotEqual(data, addressData)
    }
    
    func testNetworkTypesFromAddresses() throws {
        let polkadotAddress = "14iZ16K231zixpvaca4t2jMmt5DeDqeqTgfBBFCE3oUcA7v1"
        let polkadotNetworkType = try ss58.networkType(from: polkadotAddress)
        
        XCTAssertEqual(polkadotNetworkType, 0)
        
        let kusamaAddress = "CjPfzHY5h3ZLftZwfqFTKPufCVEo9Tjm4tanfDg5wW3KfM8"
        let kusamaNetworkType = try ss58.networkType(from: kusamaAddress)
        
        XCTAssertEqual(kusamaNetworkType, 2)
        
        // azero uses generic substrate addresses
        let azeroAddress = "5FndavgJ6H2KnHUZ8C7u5QAFThV3Se2z3E4nanMCYJtZKSh8"
        let azeroNetworkType = try ss58.networkType(from: azeroAddress)
        
        XCTAssertEqual(azeroNetworkType, 42)
        
        let joystreamAddress = "j4UW8myxisJrqbiGPah1vsf9ka3soLpGRLdUPS9Fdi8sFGXMa"
        let joystreamNetworkType = try ss58.networkType(from: joystreamAddress)
        
        XCTAssertEqual(joystreamNetworkType, 126)
    }
    
    func testNetworkTypeThrowsError() {
        let polkadotAddress = "1" // too short address
        
        XCTAssertThrowsError(try ss58.networkType(from: polkadotAddress))
    }
    
    func testGenerateAddresses() {
        let hexString = "0x80C1B49CA830D61FCC69256C26BB5EF6A3F0E198A7A981365F038BBA42266ED7"
        let accountData = Data(hex: hexString)

        let polkadotAddress = ss58.address(from: accountData, type: 0)
        XCTAssertEqual(polkadotAddress, "13upfxwAepTxvfEEkSp567AXypn9ym5NGxsWmhdyxHXw5ocz")
        
        let kusamaAddress = ss58.address(from: accountData, type: 2)
        XCTAssertEqual(kusamaAddress, "FV9Bx1yRQDREn3AZWa7quhPGo4k68LQeqyn14vasziueRF2")
        
        // azero uses generic substrate addresses
        let alephZeroAddress = ss58.address(from: accountData, type: 42)
        XCTAssertEqual(alephZeroAddress, "5EyXXdg6o3CVV8Dinom4wxLP8CnWHTXECU92cQedQCWQuNtp")
        
        let joystreamAddress = ss58.address(from: accountData, type: 126)
        XCTAssertEqual(joystreamAddress, "j4UES6fv4fkhXKjfU4nCko73Neas5nM6PvQmTyxgwqGf3Yr1F")
        
        let cessAddress = ss58.address(from: accountData, type: 11331)
        XCTAssertEqual(cessAddress, "ce6GhSBHQMxgzSftDsq67a4XWfjBgxPBux9HTw8ZHr7ZHFJQf")
    }
    
    func testIsValidAddressTrue() {
        let polkadotAddress = "13upfxwAepTxvfEEkSp567AXypn9ym5NGxsWmhdyxHXw5ocz"
        XCTAssertTrue(ss58.isValidAddress(polkadotAddress, type: 0))
        
        let kusamaAddress = "FV9Bx1yRQDREn3AZWa7quhPGo4k68LQeqyn14vasziueRF2"
        XCTAssertTrue(ss58.isValidAddress(kusamaAddress, type: 2))
        
        // azero uses generic substrate addresses
        let alephZeroAddress = "5EyXXdg6o3CVV8Dinom4wxLP8CnWHTXECU92cQedQCWQuNtp"
        XCTAssertTrue(ss58.isValidAddress(alephZeroAddress, type: 42))
        
        let joystreamAddress = "j4UES6fv4fkhXKjfU4nCko73Neas5nM6PvQmTyxgwqGf3Yr1F"
        XCTAssertTrue(ss58.isValidAddress(joystreamAddress, type: 126))
    }
    
    func testIsValidAddressFalse() {
        let invalidPolkadotAddress = "13upfxwAepTxvfEEkSp567Xypn9ym5NGxsWmhdyxHXw5ocz"
        XCTAssertFalse(ss58.isValidAddress(invalidPolkadotAddress, type: 0))
        
        let invalidKusamaAddress = "FV9Bx1yRQDREn3AZWa7quhPG4k68LQeqyn14vasziueRF2"
        XCTAssertFalse(ss58.isValidAddress(invalidKusamaAddress, type: 2))
        
        // azero uses generic substrate addresses
        let invalidAlephZeroAddress = "5EyXXdg6o3CVV8Dinom4w55LP8CnWHTXECU92cQedQCWQuNtp"
        XCTAssertFalse(ss58.isValidAddress(invalidAlephZeroAddress, type: 42))
        
        let invalidJoystreamAddress = "j4UES6fv4fkhXKjfU4nCk55o73Neas5nM6PvQmTyxgwqGf3Yr1F"
        XCTAssertFalse(ss58.isValidAddress(invalidJoystreamAddress, type: 126))
        
        let validPolkadotAddress = "13upfxwAepTxvfEEkSp567AXypn9ym5NGxsWmhdyxHXw5ocz"
        XCTAssertFalse(ss58.isValidAddress(validPolkadotAddress, type: 1))
    }
    
    
    func testRawBytesFalse() {
        let polkadotAddress = "13upfxwAepTxvfEEkSp567AXypn9ym5NGxsWmhdyxHXw5ocz"
        
        let bytes = ss58.bytes(string: polkadotAddress, raw: false)
        XCTAssertEqual(bytes.hexString, "0080C1B49CA830D61FCC69256C26BB5EF6A3F0E198A7A981365F038BBA42266ED7")
    }
    
    func testRawBytesTrue() {
        let polkadotAddress = "13upfxwAepTxvfEEkSp567AXypn9ym5NGxsWmhdyxHXw5ocz"
        
        let bytes = ss58.bytes(string: polkadotAddress, raw: true)
        XCTAssertEqual(bytes.hexString, "80C1B49CA830D61FCC69256C26BB5EF6A3F0E198A7A981365F038BBA42266ED7")
    }
}
