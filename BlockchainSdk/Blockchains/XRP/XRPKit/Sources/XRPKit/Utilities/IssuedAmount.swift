//
//  IssuedAmount.swift
//  XRPKit
//
//  Created by Mitch Lang on 5/9/19.
//

import Foundation

class IssuedAmount {
    
    let MIN_MANTISSA: Int64 = 1000000000000000 //10^15
    let MAX_MANTISSA: Int64 = 10000000000000000 - 1 //10^16-1
    let MIN_EXP = -96
    let MAX_EXP = 80
    
    var stringVal: String!
    var decimal: Decimal!
    
    init(value: String) {
        self.stringVal = value
        
        if let value = Decimal(string: stringVal) {
            self.decimal = value
        } else {
            fatalError()
        }
    }
    
    func canonicalize() -> Data {
        if self.decimal == 0 {
            return canonicalZeroSerial()
        }
        
        let sign = decimal.sign
        var exponent:Int = decimal.exponent
        let digits = stringVal.replacingOccurrences(of: ".", with: "")
        var mantissa:UInt64 = UInt64(digits)!
        
        while mantissa < MIN_MANTISSA && exponent > MIN_EXP {
            mantissa = mantissa * 10
            exponent = exponent - 1
        }
        
        while mantissa > MAX_MANTISSA {
            if exponent > MAX_EXP {
                fatalError()
            }
            mantissa = mantissa / 10
            exponent = exponent + 1
        }
        
        if exponent < MIN_EXP || mantissa < MIN_MANTISSA {
            return self.canonicalZeroSerial()
        }
        
        if exponent > MAX_EXP || mantissa > MAX_MANTISSA {
            fatalError()
        }
        
        var serial: UInt64 = 0x8000000000000000 // "Not XRP" bit set
        if sign == .plus {
            serial = serial | 0x4000000000000000 // "Is positive" bit set
        }
        serial |= (UInt64(exponent+97) << 54) // next 8 bits are exponent
        serial |= mantissa // last 54 bits are mantissa
        return serial.bigEndian.data
    }
    
    func canonicalZeroSerial() -> Data {
        /*
        Returns canonical format for zero (a special case):
        - "Not XRP" bit = 1
        - Everything else is zeroes
        - Arguably this means it's canonically written as "negative zero"
          because the encoding usually uses 1 for positive.
        */
        var zero: [UInt8] = Array(repeating: 0, count: 8)
        zero[0] = 0x80
        return Data(zero)
    }
}
