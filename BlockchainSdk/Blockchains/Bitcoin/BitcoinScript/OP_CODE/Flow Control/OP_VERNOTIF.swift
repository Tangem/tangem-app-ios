//
//  OP_VERNOTIF.swift
//  BitcoinKit
//
//  Created by Shun Usami on 2018/08/08.
//  Copyright © 2018 BitcoinKit developers. All rights reserved.
//

import Foundation

struct OpVerNotIf: OpCodeProtocol {
    var value: UInt8 { return 0x66 }
    var name: String { return "OP_VERNOTIF" }
}
