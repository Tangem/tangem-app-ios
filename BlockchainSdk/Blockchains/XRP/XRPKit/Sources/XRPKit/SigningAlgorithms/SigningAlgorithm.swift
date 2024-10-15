//
//  File.swift
//  
//
//  Created by Mitch Lang on 1/31/20.
//

import Foundation

protocol SigningAlgorithm {
    static func deriveKeyPair(seed: [UInt8]) throws -> XRPKeyPair
    static func sign(message: [UInt8], privateKey: [UInt8]) throws -> [UInt8]
    static func verify(signature: [UInt8], message: [UInt8], publicKey: [UInt8]) throws -> Bool
}
