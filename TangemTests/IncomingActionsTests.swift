//
//  IncomingActionsTests.swift
//  TangemTests
//
//  Created by Alexander Osokin on 01.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import Tangem

class IncomingActionsTests: XCTestCase {
    func testIntents() {
        let parser = IncomingActionParser()
        XCTAssertNil(parser.parseIntent("AnyWrongIntent"))
        XCTAssertNotNil(parser.parseIntent("ScanTangemCardIntent"))
    }

    func testDeeplinks() {
        let parser = IncomingActionParser()
        XCTAssertNil(parser.parseDeeplink(URL(string: "https://google.com")!))
        XCTAssertNil(parser.parseDeeplink(URL(string: "test://")!))
        XCTAssertNil(parser.parseDeeplink(URL(string: "https://tangem.com/abc")!))
        XCTAssertNil(parser.parseDeeplink(URL(string: "https://app.tangem.com/abc")!))
        XCTAssertNil(parser.parseDeeplink(URL(string: "tangem://abc")!))
        XCTAssertNil(parser.parseDeeplink(URL(string: "tangem://ndef")!))
        XCTAssertNil(parser.parseDeeplink(URL(string: "https://tangem.com/ndef")!))
        XCTAssertNil(parser.parseDeeplink(URL(string: "tangem://abc?uri=wc:12e2e015-0ae0-4bac-9d2b-b67244388eb9@1?bridge=https%3A%2F%2Fw.bridge.walletconnect.org&key=aede7f2aedde949ef1812ac624362a53737dd57acdce2d0e44b247a109d87d98")!))
        XCTAssertNil(parser.parseDeeplink(URL(string: "https://tangem.com/redirect")!))

        XCTAssertNotNil(parser.parseDeeplink(URL(string: "https://app.tangem.com/ndef")!))
        XCTAssertNotNil(parser.parseDeeplink(URL(string: "https://tangem.com/wc?uri=wc:8ad9144fec726c592b3bae26e2fa797e61b08d523fe9036ac7fe4f3c54b7b9f4@2?relay-protocol=irn&symKey=cc2f1426571a59111059b7661c6aecadc08784d299a2dce36c576844e40d6c81")!))
    }

    func testWC2Link() {
        let parser = WalletConnectURLParser()
        let uri = parser.parse(URL(string: "tangem://wc?uri=wc:8ad9144fec726c592b3bae26e2fa797e61b08d523fe9036ac7fe4f3c54b7b9f4@2?relay-protocol=irn&symKey=cc2f1426571a59111059b7661c6aecadc08784d299a2dce36c576844e40d6c81")!)

        switch uri {
        case .v2:
            XCTAssertTrue(true)
        default:
            XCTAssertTrue(false)
        }
    }

    func testWC2LinkFromString() {
        let parser = WalletConnectURLParser()
        let uri = parser.parse("wc:8ad9144fec726c592b3bae26e2fa797e61b08d523fe9036ac7fe4f3c54b7b9f4@2?relay-protocol=irn&symKey=cc2f1426571a59111059b7661c6aecadc08784d299a2dce36c576844e40d6c81")

        switch uri {
        case .v2:
            XCTAssertTrue(true)
        default:
            XCTAssertTrue(false)
        }
    }
}
