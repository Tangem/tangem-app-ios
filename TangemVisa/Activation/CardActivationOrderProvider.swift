//
//  CardActivationOrderProvider.swift
//  TangemVisa
//
//  Created by Andrew Son on 25.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol CardActivationOrderProvider {
    func provideActivationOrderForSign() async throws
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
    func provideActivationOrderForSign() async throws {
        // TODO: IOS-8572
    }

    func cancelOrderLoading() {
        // TODO: IOS-8572
    }
}
