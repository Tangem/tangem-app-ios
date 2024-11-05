//
//  TransactionSizeTesterUtility.swift
//  BlockchainSdkTests
//
//  Created by Andrew Son on 19/10/22.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import XCTest

final class TransactionSizeTesterUtility {
    private let iPhone7MaxSize = 150
    private let cos_4_52_MaxSize = 255
    private let cos_4_52_AndAboveMaxSize = 944

    func testTxSize(_ data: Data?, file: String = #fileID, function: String = #function) {
        guard let data = data else {
            XCTFail("Transaction data for size test is nil")
            return
        }

        let callerFunction = "\(file) - \(function). TX size = \(data.count)"
        XCTAssertTrue(isValidForiPhone7(data), "Testing tx size for iPhone 7 from: \(callerFunction)")
        XCTAssertTrue(isValidForCosBelow4_52(data), "Testing tx size for COS below 4.52 from: \(callerFunction)")
        XCTAssertTrue(isValidForCos4_52AndAbove(data), "Testing tx size for COS 4.52 and above from: \(callerFunction)")
    }

    func testTxSizes(_ data: [Data], file: String = #fileID, function: String = #function) {
        data.forEach {
            testTxSize($0, file: file, function: function)
        }
    }

    func isValidForiPhone7(_ data: Data) -> Bool {
        testSize(data: data, maxSize: iPhone7MaxSize)
    }

    func isValidForCosBelow4_52(_ data: Data) -> Bool {
        testSize(data: data, maxSize: cos_4_52_MaxSize)
    }

    func isValidForCos4_52AndAbove(_ data: Data) -> Bool {
        testSize(data: data, maxSize: cos_4_52_AndAboveMaxSize)
    }

    private func testSize(data: Data, maxSize: Int) -> Bool {
        data.count <= maxSize
    }
}
