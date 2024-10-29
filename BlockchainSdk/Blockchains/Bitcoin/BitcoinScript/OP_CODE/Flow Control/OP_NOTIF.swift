//
//  OP_NOTIF.swift
//  BitcoinKit
//
//  Created by Shun Usami on 2018/08/08.
//  Copyright © 2018 BitcoinKit developers. All rights reserved.
//

import Foundation

struct OpNotIf: OpCodeProtocol {
    var value: UInt8 { return 0x64 }
    var name: String { return "OP_NOTIF" }
}
