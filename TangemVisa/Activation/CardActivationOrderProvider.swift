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
    func provideActivationOrderForSign() async throws -> CardActivationOrder
    func cancelOrderLoading()
}

struct CardActivationOrder {
    let activationOrder: String
    let dataToSignByCard: Data
    let dataToSignByWallet: Data
}

final class CommonCardActivationOrderProvider {
    private let accessTokenProvider: AuthorizationTokenHandler
    private let customerInfoManagementService: CustomerInfoManagementService
    private let logger: InternalLogger

    private var loadedOrder: CardActivationOrder?
    private var orderLoadingTask: Task<Void, Error>?

    init(
        accessTokenProvider: AuthorizationTokenHandler,
        customerInfoManagementService: CustomerInfoManagementService,
        logger: InternalLogger
    ) {
        self.accessTokenProvider = accessTokenProvider
        self.customerInfoManagementService = customerInfoManagementService
        self.logger = logger
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        logger.debug(subsystem: .cardActivationOrderProvider, message())
    }
}

extension CommonCardActivationOrderProvider: CardActivationOrderProvider {
    func provideActivationOrderForSign() async throws -> CardActivationOrder {
        if let loadedOrder {
            return loadedOrder
        }

        guard let accessToken = await accessTokenProvider.accessToken else {
            throw VisaActivationError.missingAccessToken
        }

        guard let customerId = JWTTokenHelper().getCustomerID(from: accessToken) else {
            throw VisaActivationError.missingCustomerId
        }

        let customerInfo = try await customerInfoManagementService.loadCustomerInfo(customerId: customerId)
        log("Loaded customer info: \(customerInfo)")
        // TODO: IOS-8572
        try await Task.sleep(seconds: 5)
        let random = Int.random(in: 1 ... 2)
        if random % 2 == 0 {
            throw "Not implemented"
        } else {
            return .init(
                activationOrder: "Activation order to sign",
                dataToSignByCard: Data(),
                dataToSignByWallet: Data()
            )
        }
    }

    func provideActivationOrderForSign(completion: @escaping (Result<CardActivationOrder, any Error>) -> Void) {
        if let loadedOrder {
            completion(.success(loadedOrder))
            return
        }

        // TODO: IOS-8572
        if let orderLoadingTask {
            orderLoadingTask.cancel()
            self.orderLoadingTask = nil
        }

        orderLoadingTask = Task { [weak self] in
            guard let self else { return }

            do {
                let order = try await provideActivationOrderForSign()
                completion(.success(order))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func cancelOrderLoading() {
        // TODO: IOS-8572
        orderLoadingTask?.cancel()
    }
}
