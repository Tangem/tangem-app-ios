//
//  AnyEncodable.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 08.04.2024.
//

import Foundation

struct AnyEncodable: Encodable {
    private let encodable: Encodable

    init(_ encodable: Encodable) {
        self.encodable = encodable
    }

    func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}
