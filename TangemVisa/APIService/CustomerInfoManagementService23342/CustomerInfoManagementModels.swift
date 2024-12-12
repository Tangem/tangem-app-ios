//
//  CustomerResponse.swift
//  TangemApp
//
//  Created by Andrew Son on 02.12.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CustomerResponse: Decodable {
    let customerId: String
    let customerNumber: String?
    let customerStatus: String
    let createdAt: Date
    let paymentAccounts: [PaymentAccount]?
    let productInstances: [ProductInstance]?
    let kyc: KYC?
    let kyt: KYT?
    let profile: Profile?
}

extension CustomerResponse {
    struct PaymentAccount: Decodable {
        let id: String
        let customerWalletAddress: String
        let paymentAccountAddress: String
    }

    struct ProductInstance: Decodable {
        let id: String
        let paymentAccountId: String
        let cid: String?
        let status: String
        let issuer: String
    }

    struct KYC: Decodable {
        let status: String
        let risk: String
        let updatedAt: String
    }

    struct KYT: Decodable {
        let risk: String
        let updatedAt: String
    }

    struct Profile: Decodable {
        let firstName: String
        let lastName: String
    }
}

enum KYCStatus: String {
    case required = "REQUIRED"
    case inProgress = "IN_PROGRESS"
    case passed = "PASSED"
    case failed = "FAILED"
    case blocked = "BLOCKED"
}

enum KYCRisk: String {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    case veryHigh = "VERY_HIGH"
    case unknown = "UNKNOWN"
}

enum KYTRisk: String {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    case veryHigh = "VERY_HIGH"
    case unknown = "UNKNOWN"
}
