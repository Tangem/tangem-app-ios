//
//  TargetTypeLogConvertible.swift
//  TangemModules
//
//  Created by Alexander Osokin on 04.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public protocol TargetTypeLogConvertible {
    var requestDescription: String { get }
    var shouldLogResponseBody: Bool { get }
}

public extension TargetTypeLogConvertible {
    var shouldLogResponseBody: Bool { true }
}
