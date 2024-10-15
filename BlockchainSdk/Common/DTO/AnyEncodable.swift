//
//  AnyEncodable.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 08.04.2024.
//

import Foundation

public struct AnyEncodable: Encodable {
    private let encodable: Encodable

    public init(_ encodable: Encodable) {
        self.encodable = encodable
    }

    public func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}
