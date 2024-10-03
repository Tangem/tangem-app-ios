//
//  VisaAPIService.swift
//  TangemVisa
//
//  Created by Andrew Son on 23/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol VisaAPIService {
    func loadHistoryPage(request: VisaTransactionHistoryDTO.APIRequest) async throws -> VisaTransactionHistoryDTO
}
