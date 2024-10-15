//
//  XRPAccountInfo.swift
//  BigInt
//
//  Created by Mitch Lang on 2/3/20.
//

import Foundation

public struct XRPAccountInfo: Codable {
    public var address: String
    public var drops: Int
    public var sequence: Int
}
