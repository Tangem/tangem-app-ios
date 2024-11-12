//
//  CommonVisaTransactionHistoryAPIService.swift
//  TangemVisa
//
//  Created by Andrew Son on 24/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct VisaPayAPIService {
    private let apiService: APIService<VisaPayAPITarget, VisaAPIError>

    private let isTestnet: Bool
    private let additionalAPIHeaders: [String: String]

    init(isTestnet: Bool, additionalAPIHeaders: [String: String], logger: InternalLogger) {
        self.isTestnet = isTestnet
        self.additionalAPIHeaders = additionalAPIHeaders

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        apiService = .init(
            provider: .init(),
            logger: logger,
            decoder: decoder
        )
    }
}

extension VisaPayAPIService: VisaTransactionHistoryAPIService {
    func loadHistoryPage(request: VisaTransactionHistoryDTO.APIRequest) async throws -> VisaTransactionHistoryDTO {
        try await apiService.request(.init(
            isTestnet: isTestnet,
            target: .transactionHistory(request: request),
            additionalHeaders: additionalAPIHeaders
        ))
    }
}
