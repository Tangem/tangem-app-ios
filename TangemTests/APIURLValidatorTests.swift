//
//  APIURLValidatorTests.swift
//  TangemTests
//
//  Created by Andrew Son on 05/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import XCTest
@testable import Tangem

final class APIURLValidatorTests: XCTestCase {
    func testAPILinks() throws {
        let validator = APIURLValidator()

        XCTAssertNotNil(validator.regex, "APIURLValidator has invalid pattern")

        XCTAssertTrue(validator.isLinkValid("http://fullnode.mainnet.aptoslabs.com/"))
        XCTAssertTrue(validator.isLinkValid("https://fullnode.mainnet.aptoslabs.com/"))
        XCTAssertTrue(validator.isLinkValid("wss://electrumx-01-ssl.radiant4people.com:51002/"))
        XCTAssertTrue(validator.isLinkValid("rtsp://someRtspServer.com"))

        XCTAssertFalse(validator.isLinkValid("httretrewyrtwytrwtps://fullnode.mainnet.aptoslabs.com/"))
        XCTAssertFalse(validator.isLinkValid("     httretrewyrtwytrwtps://fullnode.mainnet.aptoslabs.com/      "))
        XCTAssertFalse(validator.isLinkValid("httttps://rpc.azero.dev/"))
        XCTAssertFalse(validator.isLinkValid("ht_tps://aleph-zero-rpc.dwellir.com/"))
        XCTAssertFalse(validator.isLinkValid("htv vfs gfsrw tps://fullnode.mainnet.aptoslabs.com/"))
        XCTAssertFalse(validator.isLinkValid("http___s://fullnode.mainnet.aptoslabs.com/"))
        XCTAssertFalse(validator.isLinkValid("fullnode.mainnet.aptoslabs.com/"))
        XCTAssertFalse(validator.isLinkValid("some-invalid---.com"))
        XCTAssertFalse(validator.isLinkValid("https://some-in v a l i d---.com"))
        XCTAssertFalse(validator.isLinkValid("1235940328:4839205314321"))
        XCTAssertFalse(validator.isLinkValid("justRandomText"))
        XCTAssertFalse(validator.isLinkValid(""))
    }
}
