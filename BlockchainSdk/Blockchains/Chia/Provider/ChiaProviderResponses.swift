//
//  ChiaProviderResponse.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 15.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol ChiaStatusResponse: Decodable {
    var success: Bool { get }
}

struct ChiaCoinRecordsResponse: ChiaStatusResponse {
    let success: Bool
    let coinRecords: [ChiaCoinRecord]
}

struct ChiaSendTransactionResponse: ChiaStatusResponse {
    let success: Bool
    let status: String?
    let error: String?
}

extension ChiaSendTransactionResponse {
    enum Constants {
        static let successStatus: String = "SUCCESS"
    }
}

struct ChiaEstimateFeeResponse: ChiaStatusResponse {
    let success: Bool
    let estimates: [Int64]
    let feeRateLastBlock: Double
    let currentFeeRate: Double
}

struct ChiaCoinRecord: Decodable {
    let coin: ChiaCoin
}
