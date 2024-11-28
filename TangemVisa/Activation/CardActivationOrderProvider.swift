//
//  CardActivationOrderProvider.swift
//  TangemVisa
//
//  Created by Andrew Son on 25.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol CardActivationOrderProvider: AnyObject {
    func provideActivationOrderForSign() async throws -> String
    func cancelOrderLoading()
}

final class CommonCardActivationOrderProvider {
    private let accessTokenProvider: AuthorizationTokenHandler
    private let customerInfoService: CustomerInfoService
    private let logger: InternalLogger

    init(
        accessTokenProvider: AuthorizationTokenHandler,
        customerInfoService: CustomerInfoService,
        logger: InternalLogger
    ) {
        self.accessTokenProvider = accessTokenProvider
        self.customerInfoService = customerInfoService
        self.logger = logger
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        logger.debug(subsystem: .cardActivationOrderProvider, message())
    }
}

extension CommonCardActivationOrderProvider: CardActivationOrderProvider {
    func provideActivationOrderForSign() async throws -> String {
        // TODO: IOS-8572
        try await Task.sleep(seconds: 5)
        let random = Int.random(in: 1 ... 2)
        if random % 2 == 0 {
            throw "Not implemented"
        } else {
            return "Activation order to sign"
        }
    }

    func cancelOrderLoading() {
        // TODO: IOS-8572
    }
}
