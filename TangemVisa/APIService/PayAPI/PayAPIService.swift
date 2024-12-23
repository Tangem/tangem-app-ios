//
//  PayAPIService.swift
//  TangemVisa
//
//  Created by Andrew Son on 24/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct PayAPIService {
    private let apiService: APIService<PayAPITarget, VisaAPIError>

    private let isTestnet: Bool
    private let additionalAPIHeaders: [String: String]

    init(
        isTestnet: Bool,
        additionalAPIHeaders: [String: String],
        apiService: APIService<PayAPITarget, VisaAPIError>
    ) {
        self.isTestnet = isTestnet
        self.additionalAPIHeaders = additionalAPIHeaders
        self.apiService = apiService
    }
}

extension PayAPIService: VisaTransactionHistoryAPIService {
    func loadHistoryPage(request: VisaTransactionHistoryDTO.APIRequest) async throws -> VisaTransactionHistoryDTO {
        return try await apiService.request(.init(
            isTestnet: isTestnet,
            target: .transactionHistory(request: request),
            additionalHeaders: additionalAPIHeaders
        ))
    }
}
