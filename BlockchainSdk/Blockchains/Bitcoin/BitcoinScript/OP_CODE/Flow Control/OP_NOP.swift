//
//  OP_NOP.swift
//  BitcoinKit
//
//  Created by Shun Usami on 2018/08/08.
//  Copyright © 2018 BitcoinKit developers. All rights reserved.
//

import Foundation

// do nothing
struct OpNop: OpCodeProtocol {
    var value: UInt8 { return 0x61 }
    var name: String { return "OP_NOP" }
}
