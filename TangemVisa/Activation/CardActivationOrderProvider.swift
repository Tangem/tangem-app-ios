//
//  CardActivationOrderProvider.swift
//  TangemVisa
//
//  Created by Andrew Son on 25.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import JWTDecode

protocol CardActivationOrderProvider {
    func provideActivationOrderForSign() async throws
    func cancelOrderLoading()
}

final class CommonCardActivationOrderProvider {
    private let accessTokenProvider: AuthorizationTokenHandler
    private let customerInfoService: CustomerInfoManagementService
    private let logger: InternalLogger

    init(
        accessTokenProvider: AuthorizationTokenHandler,
        customerInfoService: CustomerInfoManagementService,
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
        guard let accessToken = await accessTokenProvider.accessToken else {
            throw VisaActivationError.missingAccessCode
        }

        guard let customerId = JWTTokenHelper().getCustomerID(from: accessToken) else {
            throw VisaActivationError.missingCustomerId
        }

        let customerInfo = try await customerInfoService.loadCustomerInfo(customerId: customerId)
        log("Loaded customer info: \(customerInfo)")
        // TODO: IOS-8572
    }

    func cancelOrderLoading() {
        // TODO: IOS-8572
    }
}
