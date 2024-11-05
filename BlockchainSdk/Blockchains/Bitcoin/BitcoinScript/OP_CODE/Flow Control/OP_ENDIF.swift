//
//  OP_ENDIF.swift
//  BitcoinKit
//
//  Created by Shun Usami on 2018/08/08.
//  Copyright © 2018 BitcoinKit developers. All rights reserved.
//

import Foundation

struct OpEndIf: OpCodeProtocol {
    var value: UInt8 { return 0x68 }
    var name: String { return "OP_ENDIF" }
}
