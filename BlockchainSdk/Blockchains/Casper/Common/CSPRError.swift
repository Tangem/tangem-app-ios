//
//  CasperError.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 31.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum CSPRError: Error {
    case invalidNumber
    case none
}

enum CSPRMethodError: Error {
    case invalidURL
    case invalidParams
    case parseError
    case methodNotFound
    case unknown
    case getDataBackError
    case NONE
}

enum CSPRMethodCallError: Error {
    case casperError(code: Int, message: String, methodCall: String)
    case none
}
