//
//  ProductActivationAPIModels.swift
//  TangemVisa
//
//  Created by Andrew Son on 31/01/25.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Activation status

extension ProductActivationAPITarget {
    struct ActivationStatusRequest {
        let customerId: String
        let productInstanceId: String
        let cardId: String
        let cardPublicKey: String
    }
}

extension ProductActivationAPITarget {
    struct ProductActivationEmptyResponse: Decodable {}
}

// MARK: - Visa card deploy acceptance requests - 2 tap related

extension ProductActivationAPITarget {
    // Requests
    struct DataToSignByVisaCardRequest {
        let customerId: String
        let productInstanceId: String
        let activationOrderId: String
        let customerWalletAddress: String
    }

    struct VisaCardDeployAcceptanceRequest: Encodable {
        let customerId: String
        let productInstanceId: String
        let activationOrderId: String
        let data: DeployAcceptanceDataContainer
    }

    // Responses
    struct DataToSignByVisaCardResponse: Decodable {
        let dataForCardWallet: DataToSignByCardResponseData
    }

    struct DataToSignByCustomerWalletReponse: Decodable {
        let dataForCustomerWallet: DataToSignByCardResponseData
    }

    struct DataToSignByCardResponseData: Decodable {
        let hash: String
    }
}

extension ProductActivationAPITarget.VisaCardDeployAcceptanceRequest {
    // Related data
    struct DeployAcceptanceDataContainer: Encodable {
        let cardWallet: DeployAcceptanceData
        let otp: OTPData
    }

    struct DeployAcceptanceData: Encodable {
        let address: String
        let deployAcceptanceSignature: String
        let cardWalletConfirmation: SignatureData?
    }

    struct OTPData: Encodable {
        let rootOtp: String
        let counter: Int
    }

    struct SignatureData: Encodable {
        let challenge: String
        let walletSignature: String
        let cardSalt: String
        let cardSignature: String
    }
}

// MARK: - Customer wallet deploy acceptance requests - 3 tap related

extension ProductActivationAPITarget {
    struct DataToSignByCustomerWalletRequest {
        let customerId: String
        let productInstanceId: String
        let activationOrderId: String
        let cardWalletAddress: String
    }

    struct CustomerWalletDeployAcceptanceRequest: Encodable {
        let customerId: String
        let productInstanceId: String
        let activationOrderId: String
        let data: DeployAcceptanceDataContainer
    }
}

extension ProductActivationAPITarget.CustomerWalletDeployAcceptanceRequest {
    struct DeployAcceptanceDataContainer: Encodable {
        let customerWallet: AcceptanceData
    }

    struct AcceptanceData: Encodable {
        let address: String
        let deployAcceptanceSignature: String
    }
}

// MARK: - PIN code related

extension ProductActivationAPITarget {
    struct IssuerActivationRequest: Encodable {
        let customerId: String
        let productInstanceId: String
        let activationOrderId: String
        let data: IssuerActivationData
    }
}

extension ProductActivationAPITarget.IssuerActivationRequest {
    struct IssuerActivationData: Encodable {
        let sessionKey: String
        let iv: String
        let encryptedPin: String
    }
}
