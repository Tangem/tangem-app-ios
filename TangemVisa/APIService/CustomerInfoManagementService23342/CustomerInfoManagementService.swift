//
//  CustomerInfoManagementService.swift
//  TangemVisa
//
//  Created by Andrew Son on 22.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

protocol CustomerInfoManagementService {
    func loadCustomerInfo(customerId: String) async throws -> CustomerResponse
}

class CommonCustomerInfoService {
    typealias CIMAPIService = APIService<CustomerInfoManagementAPITarget, VisaAPIError>
    private let accessTokenProvider: AuthorizationTokenHandler
    private let apiService: CIMAPIService

    init(
        accessTokenProvider: AuthorizationTokenHandler,
        apiService: CIMAPIService
    ) {
        self.accessTokenProvider = accessTokenProvider
        self.apiService = apiService
    }

    private func makeRequest(for target: CustomerInfoManagementAPITarget.Target) async throws -> CustomerInfoManagementAPITarget {
        let authorizationToken = try await accessTokenProvider.authorizationHeader

        return .init(
            authorizationToken: authorizationToken,
            target: target
        )
    }
}

extension CommonCustomerInfoService: CustomerInfoManagementService {
    func loadCustomerInfo(customerId: String) async throws -> CustomerResponse {
        return try await apiService.request(
            makeRequest(for: .getCustomerInfo(customerId: customerId))
        )
    }
}
