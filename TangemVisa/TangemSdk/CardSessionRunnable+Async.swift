//
//  CardSessionRunnable+Async.swift
//  TangemVisa
//
//  Created by Andrew Son on 25.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

extension CardSessionRunnable {
    func run(in cardSession: CardSession) async throws -> Response {
        try await withCheckedThrowingContinuation { continuation in
            run(in: cardSession) { result in
                continuation.resume(with: result)
            }
        }
    }
}
