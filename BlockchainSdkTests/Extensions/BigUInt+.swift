//
//  BigUInt+.swift
//  BlockchainSdkTests
//
//  Created by Andrey Chukavin on 17.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import XCTest
import BigInt

final class BigUInt_: XCTestCase {
    func testDecimalToBigUInt() throws {
        let decimalToBigUIntFormatted: (String) -> String = { string in
            let decimal = Decimal(string: string)
            XCTAssertNotNil(decimal)
            
            let bigUInt = BigUInt(decimal: decimal!)
            XCTAssertNotNil(bigUInt)
            
            return String(bigUInt!)
        }
        
        // Good numbers
        let validStrings = [
            "0",
            "1",
            "1234567890",
            "123456789012345678901234567890",
        ]
        for string in validStrings {
            XCTAssertEqual(string, decimalToBigUIntFormatted(string))
        }
        
        // Overflows
        let invalidStrings = [
            "123456789012345678901234567890123456789012345678901234567890",
        ]
        for string in invalidStrings {
            XCTAssertNotEqual(string, decimalToBigUIntFormatted(string))
        }
        
        // Corner cases
        XCTAssertNil(BigUInt(decimal: -1))
        XCTAssertNil(BigUInt(decimal: 1.5))
    }
    
    func testBigUIntToDecimal() throws {
        // Good numbers
        let validStrings: [String] = [
            "0",
            "1",
            "1234567890",
            "12345678901234567890",
            "1234567890123456789012345678901234567890",
        ]
        for string in validStrings {
            XCTAssertEqual(BigUInt(stringLiteral: string).decimal, Decimal(string: string))
        }
        
        // Overflows
        let invalidStrings = [
            "12345678901234567890123456789012345678901234567890123456789012345678901234567890",
        ]
        for string in invalidStrings {
            XCTAssertEqual(BigUInt(stringLiteral: string).decimal, nil)
        }
    }
}
