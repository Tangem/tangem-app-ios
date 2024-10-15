//
//  XRPHistoricalTransaction.swift
//  BigInt
//
//  Created by Mitch Lang on 2/3/20.
//

import Foundation

public struct XRPHistoricalTransaction {
    public var type: String
    public var address: String
    public var amount: XRPAmount
    public var date: Date
}
