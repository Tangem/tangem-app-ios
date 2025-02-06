//
//  ProductActivationAPIService.swift
//  TangemVisa
//
//  Created by Andrew Son on 29/01/25.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol ProductActivationService {
    func getVisaCardDeployAcceptance(
        activationOrderId: String,
        customerWalletAddress: String
    ) async throws -> String
    func sendSignedVisaCardDeployAcceptance(
        activationOrderId: String,
        cardWalletAddress: String,
        signedAcceptance: String,
        rootOtp: String,
        rootOtpCounter: Int
    ) async throws

    func getCustomerWalletDeployAcceptance(
        activationOrderId: String,
        cardWalletAddress: String
    ) async throws -> String
    func sendSignedCustomerWalletDeployAcceptance(
        activationOrderId: String,
        customerWalletAddress: String,
        deployAcceptanceSignature: String
    ) async throws

    func sendSelectedPINCodeToIssuer(
        activationOrderId: String,
        sessionKey: String,
        iv: String,
        encryptedPin: String
    ) async throws
}

struct CommonProductActivationService {
    typealias ActivationAPIService = APIService<ProductActivationAPITarget, VisaAPIError>
    private let authorizationTokensHandler: AuthorizationTokensHandler
    private let apiService: ActivationAPIService

    init(
        authorizationTokensHandler: AuthorizationTokensHandler,
        apiService: ActivationAPIService
    ) {
        self.authorizationTokensHandler = authorizationTokensHandler
        self.apiService = apiService
    }

    private func getEssentialActivationIds() async throws -> (customerId: String, productInstanceId: String) {
        guard let accessToken = await authorizationTokensHandler.accessToken else {
            throw VisaActivationError.missingAccessToken
        }

        return try VisaActivationUtility().getEssentialActivationIds(from: accessToken)
    }

    private func sendRequest<T: Decodable>(target: ProductActivationAPITarget.Target) async throws -> T {
        let authorizationToken = try await authorizationTokensHandler.authorizationHeader

        return try await apiService.request(.init(target: target, authorizationToken: authorizationToken))
    }
}

extension CommonProductActivationService: ProductActivationService {
    func getVisaCardDeployAcceptance(
        activationOrderId: String,
        customerWalletAddress: String
    ) async throws -> String {
        let ids = try await getEssentialActivationIds()
        let response: ProductActivationAPITarget.DataToSignByVisaCardResponse = try await sendRequest(
            target: .getDataToSignByVisaCard(request: .init(
                customerId: ids.customerId,
                productInstanceId: ids.productInstanceId,
                activationOrderId: activationOrderId,
                customerWalletAddress: customerWalletAddress
            ))
        )
        return response.dataForCardWallet.hash
    }

    func sendSignedVisaCardDeployAcceptance(
        activationOrderId: String,
        cardWalletAddress: String,
        signedAcceptance: String,
        rootOtp: String,
        rootOtpCounter: Int
    ) async throws {
        let ids = try await getEssentialActivationIds()
        let defaultEmptyValue = "N/A"
        let data: ProductActivationAPITarget.VisaCardDeployAcceptanceRequest.DeployAcceptanceDataContainer = .init(
            cardWallet: .init(
                address: cardWalletAddress,
                deployAcceptanceSignature: signedAcceptance,
                cardWalletConfirmation: .init(
                    challenge: defaultEmptyValue,
                    walletSignature: defaultEmptyValue,
                    cardSalt: defaultEmptyValue,
                    cardSignature: defaultEmptyValue
                )
            ),
            otp: .init(
                rootOtp: rootOtp,
                counter: rootOtpCounter
            )
        )
        let response: ProductActivationAPITarget.ProductActivationEmptyResponse = try await sendRequest(
            target: .approveDeployByVisaCard(request: .init(
                customerId: ids.customerId,
                productInstanceId: ids.productInstanceId,
                activationOrderId: activationOrderId,
                data: data
            ))
        )
    }

    func getCustomerWalletDeployAcceptance(
        activationOrderId: String,
        cardWalletAddress: String
    ) async throws -> String {
        let ids = try await getEssentialActivationIds()
        let response: ProductActivationAPITarget.DataToSignByCustomerWalletReponse = try await sendRequest(
            target: .getDataToSignByCustomerWallet(request: .init(
                customerId: ids.customerId,
                productInstanceId: ids.productInstanceId,
                activationOrderId: activationOrderId,
                cardWalletAddress: cardWalletAddress
            ))
        )
        return response.dataForCustomerWallet.hash
    }

    func sendSignedCustomerWalletDeployAcceptance(
        activationOrderId: String,
        customerWalletAddress: String,
        deployAcceptanceSignature: String
    ) async throws {
        let ids = try await getEssentialActivationIds()
        let data: ProductActivationAPITarget.CustomerWalletDeployAcceptanceRequest.AcceptanceData = .init(
            address: customerWalletAddress,
            deployAcceptanceSignature: deployAcceptanceSignature
        )
        let _: ProductActivationAPITarget.ProductActivationEmptyResponse = try await sendRequest(
            target: .approveDeployByCustomerWallet(request: .init(
                customerId: ids.customerId,
                productInstanceId: ids.productInstanceId,
                activationOrderId: activationOrderId,
                data: .init(
                    customerWallet: data
                )
            ))
        )
    }

    func sendSelectedPINCodeToIssuer(
        activationOrderId: String,
        sessionKey: String,
        iv: String,
        encryptedPin: String
    ) async throws {
        let ids = try await getEssentialActivationIds()
        let _: ProductActivationAPITarget.ProductActivationEmptyResponse = try await sendRequest(
            target: .issuerActivation(request: .init(
                customerId: ids.customerId,
                productInstanceId: ids.productInstanceId,
                activationOrderId: activationOrderId,
                data: .init(
                    sessionKey: sessionKey,
                    iv: iv,
                    encryptedPin: encryptedPin
                )
            ))
        )
    }
}
