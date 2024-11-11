//
//  Int+.swift
//  TangemFoundation
//
//  Created by Alexander Osokin on 10.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public extension Int {
    /// return 2 bytes of integer. LittleEndian format
    var bytes2LE: Data {
        let clamped = UInt16(clamping: self)
        let data = withUnsafeBytes(of: clamped) { Data($0) }
        return data
    }

    /// return 4 bytes of integer. LittleEndian format
    var bytes4LE: Data {
        let clamped = UInt32(clamping: self)
        let data = withUnsafeBytes(of: clamped) { Data($0) }
        return data
    }

    /// return 8 bytes of integer. LittleEndian  format
    var bytes8LE: Data {
        let data = withUnsafeBytes(of: self) { Data($0) }
        return data
    }
}
