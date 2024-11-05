//
//  XRPAccountInfo.swift
//  BigInt
//
//  Created by Mitch Lang on 2/3/20.
//

import Foundation

struct XRPAccountInfo: Codable {
    var address: String
    var drops: Int
    var sequence: Int
}
