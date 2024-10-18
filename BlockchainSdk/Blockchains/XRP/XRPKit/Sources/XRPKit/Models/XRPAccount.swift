//
//  XRPAccount.swift
//  BigInt
//
//  Created by Mitch Lang on 2/3/20.
//

import Foundation

struct XRPAccount: Codable {
    var address: String
    var secret: String

    init(address: String, secret: String) {
        self.address = address
        self.secret = secret
    }
}
