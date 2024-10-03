//
//  OptionalProtocol.swift
//  Tangem
//
//  Created by Andrey Fedorov on 01.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// A lightweight interface that allows writing extensions with generic constraints for the `Swift.Optional` type.
protocol OptionalProtocol {
    associatedtype Wrapped

    var wrapped: Wrapped? { get }
}

extension Optional: OptionalProtocol {
    var wrapped: Wrapped? { self }
}
