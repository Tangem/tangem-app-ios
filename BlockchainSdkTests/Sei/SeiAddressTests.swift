//
//  SeiAddressTests.swift
//  BlockchainSdkTests
//
//  Created by GuitarKitty on 06.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import XCTest
import WalletCore

@testable import BlockchainSdk

final class SeiAddressTests: XCTestCase {
    private var addressService: WalletCoreAddressService!
    
    override func setUp() {
        addressService = WalletCoreAddressService(blockchain: .sei(testnet: true))
    }
    
    func testMakeAddress() throws {
        let expectedOutput = "sei12rtn7e5lh6y6zftgc69gh7a0cny44089x7j8hq"
        
        let privateKey = PrivateKey(data: Data(hex: "2c179540bebbb6b862fb20fbb6713d3c9c5fc3464da61f0292735f74f35f8586"))!
        let publicKeyData = privateKey.getPublicKeySecp256k1(compressed: true).data
        let seiAddress = try addressService.makeAddress(from: publicKeyData).value
        
        XCTAssertEqual(seiAddress, expectedOutput)
    }
    
    func testMakeInvalidAddress() throws {
        let validAddress = "sei12rtn7e5lh6y6zftgc69gh7a0cny44089x7j8hq"
        
        let privateKey = PrivateKey(data: Data(hex: "2c179540bebbb6b862fb20fbb6713d3c9c5fc3464da61f0292735f74f35f8586"))!
        let publicKeyData = privateKey.getPublicKeyEd25519().data
        
        XCTAssertThrowsError(try addressService.makeAddress(from: publicKeyData))
    }
    
    func testAddressIsValid() throws {
        XCTAssertTrue(addressService.validate("sei12rtn7e5lh6y6zftgc69gh7a0cny44089x7j8hq"))
    }
    
    func testAddressIsInvalid() throws {
        XCTAssertFalse(addressService.validate("bc1qxzdqcmh6pknevm2ugtw94y50dwhsu3l0p5tg63"))
    }
    
    override func tearDown() {
        addressService = nil
    }
}

