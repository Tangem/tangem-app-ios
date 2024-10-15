//
//  OP_ELSE.swift
//  BitcoinKit
//
//  Created by Shun Usami on 2018/08/08.
//  Copyright © 2018 BitcoinKit developers. All rights reserved.
//

import Foundation

public struct OpElse: OpCodeProtocol {
    public var value: UInt8 { return 0x67 }
    public var name: String { return "OP_ELSE" }
}
