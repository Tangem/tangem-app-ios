//
//  APIListTests.swift
//  TangemTests
//
//  Created by Andrew Son on 24/04/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import XCTest
import BlockchainSdk
@testable import Tangem

final class APIListTests: XCTestCase {
    func testParseAPIList() throws {
        let apiListUtils = APIListUtils()
        XCTAssertNoThrow(try apiListUtils.parseLocalAPIListJson())
    }

    func testLocalAPIListFulfillment() throws {
        let apiListUtils = APIListUtils()
        let apiList = try apiListUtils.parseLocalAPIListJson()

        XCTAssert(!apiList.isEmpty, "Local API list shouldn't be empty")
        Blockchain.allMainnetCases.forEach {
            let providers = apiList[$0.networkId] ?? []

            switch $0 {
            // This blockchains didn't use API list to setup providers, so we can skip them
            case .binance, .ducatus:
                return
            default:
                break
            }

            XCTAssert(!providers.isEmpty, "No providers were added in local API list for \($0.displayName)")
        }
    }
}
