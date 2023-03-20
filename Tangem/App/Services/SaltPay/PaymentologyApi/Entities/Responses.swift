//
//  Responses.swift
//  Tangem
//
//  Created by Alexander Osokin on 05.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct RegistrationResponse: Codable, ErrorContainer, ErrorExtraContainer {
    let results: [RegistrationResponse.Item]
    let error: String?
    let errorCode: Int?
    let success: Bool
}

extension RegistrationResponse {
    struct Item: Codable, ErrorContainer {
        let cardId: String
        let error: String?
        let passed: Bool?
        let active: Bool?
        var pinSet: Bool?
        let blockchainInit: Bool?
        let kycPassed: Bool?
        let kycProvider: String?
        let kycDate: String?
        let disabledByAdmin: Bool?
        var kycStatus: KYCStatus?

        enum CodingKeys: String, CodingKey {
            case cardId = "CID"
            case error
            case passed
            case active
            case pinSet = "pin_set"
            case blockchainInit = "blockchain_init"
            case kycPassed = "kyc_passed"
            case kycProvider = "kyc_provider"
            case kycDate = "kyc_date"
            case disabledByAdmin = "disabled_by_admin"
            case kycStatus = "kyc_status"
        }
    }
}

struct AttestationResponse: Codable, ErrorContainer, ErrorExtraContainer {
    let challenge: Data
    let error: String?
    let errorCode: Int?
    let success: Bool
}

struct RegisterWalletResponse: Codable, ErrorContainer, ErrorExtraContainer {
    let error: String?
    let errorCode: Int?
    let success: Bool
}

protocol ErrorContainer {
    var error: String? { get }
}

protocol ErrorExtraContainer: ErrorContainer {
    var errorCode: Int? { get }
    var success: Bool { get }
}

enum KYCStatus: String, Codable {
    case notStarted
    case started
    case waitingForApproval
    case correctionRequested
    case approved
    case rejected
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        switch rawValue {
        case "NOT_STARTED":
            self = .notStarted
        case "STARTED":
            self = .started
        case "WAITING_FOR_APPROVAL":
            self = .waitingForApproval
        case "CORRECTION_REQUESTED":
            self = .correctionRequested
        case "APPROVED":
            self = .approved
        case "REJECTED":
            self = .rejected
        default:
            self = .unknown
        }
    }
}
