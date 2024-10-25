//
//  Entropy.swift
//  XRPKit
//
//  Created by Mitch Lang on 5/23/19.
//

import Foundation

enum EntropyError: Error {
    case invalidBufferSize
}

class Entropy {
    
    private(set) var bytes: [UInt8]!
    
    init() {
        var _bytes = [UInt8](repeating: 0, count: 16)
        _bytes = try! URandom().bytes(count: 16)
//        let status = SecRandomCopyBytes(kSecRandomDefault, _bytes.count, &_bytes)
//
//        if status != errSecSuccess { // Always test the status.
//            fatalError()
//        }
        self.bytes = _bytes
    }
    
    init(bytes: [UInt8]) {
        self.bytes = bytes
    }
}
