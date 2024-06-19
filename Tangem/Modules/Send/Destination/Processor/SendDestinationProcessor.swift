//
//  SendDestinationProcessor.swift
//  Tangem
//
//  Created by Sergey Balashov on 10.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol SendDestinationProcessor {
    // Validate and resolve if needed
    func proceed(destination: String) async throws -> String
    func proceed(additionalField: String) throws -> DestinationAdditionalFieldType
}

class CommonSendDestinationProcessor: SendDestinationProcessor {
    private let validator: SendDestinationValidator
    private let addressResolver: AddressResolver?
    private let additionalFieldType: SendAdditionalFields?
    private let parametersBuilder: SendTransactionParametersBuilder

    init(
        validator: SendDestinationValidator,
        addressResolver: AddressResolver?,
        additionalFieldType: SendAdditionalFields?,
        parametersBuilder: SendTransactionParametersBuilder
    ) {
        self.validator = validator
        self.addressResolver = addressResolver
        self.additionalFieldType = additionalFieldType
        self.parametersBuilder = parametersBuilder
    }

    func proceed(destination: String) async throws -> String {
        try validator.validate(destination: destination)

        if let addressResolver = addressResolver {
            try await Task.sleep(seconds: 1)

            try Task.checkCancellation()

            let resolvedAddress = try await addressResolver.resolve(destination)
            return resolvedAddress
        }

        return destination
    }

    func proceed(additionalField: String) throws -> DestinationAdditionalFieldType {
        guard let type = additionalFieldType else {
            assertionFailure("Additional field for the blockchain whick doesn't support it")
            return .notSupported
        }

        guard let parameters = try parametersBuilder.transactionParameters(from: additionalField) else {
            // We don't have to call this code if transactionParameters doesn't exist fot this blockchain
            // Check your input parameters
            assertionFailure("Additional field for the blockchain whick doesn't support it")
            return .notSupported
        }

        return .filled(type: type, value: additionalField, params: parameters)
    }
}
