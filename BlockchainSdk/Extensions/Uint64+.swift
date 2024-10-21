//
//  Array+.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 18.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation


extension UInt64 {
    init?(data: Data) {
        guard data.count <= 8 else {
            return nil
        }
        
        let temp = NSData(bytes: data.reversed(), length: data.count)
        let rawPointer = UnsafeRawPointer(temp.bytes)
        let pointer = rawPointer.assumingMemoryBound(to: UInt64.self)
        self = pointer.pointee
    }
}
