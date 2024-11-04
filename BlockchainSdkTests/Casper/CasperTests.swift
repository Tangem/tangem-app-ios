//
//  CasperTests.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 23.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import XCTest
@testable import BlockchainSdk

final class CasperTests: XCTestCase {
    private let blockchain = Blockchain.casper(testnet: false)
}
