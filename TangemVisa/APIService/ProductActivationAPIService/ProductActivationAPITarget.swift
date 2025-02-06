//
//  ProductActivationAPITarget.swift
//  TangemVisa
//
//  Created by Andrew Son on 31/01/25.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct ProductActivationAPITarget: TargetType {
    let target: Target
    let authorizationToken: String

    var baseURL: URL {
        return VisaConstants.bffBaseURL.appendingPathComponent("product_instance/")
    }

    var path: String {
        switch target {
        case .activationStatus:
            return "activation_status"
        case .getDataToSignByVisaCard:
            return "card_wallet_acceptance"
        case .approveDeployByVisaCard:
            return "activation_by_card_wallet"
        case .getDataToSignByCustomerWallet:
            return "customer_wallet_acceptance"
        case .approveDeployByCustomerWallet:
            return "activation"
        case .issuerActivation:
            return "issuer_activation"
        }
    }

    var method: Moya.Method {
        switch target {
        case .activationStatus, .getDataToSignByVisaCard, .getDataToSignByCustomerWallet:
            return .get
        case .approveDeployByVisaCard, .approveDeployByCustomerWallet, .issuerActivation:
            return .post
        }
    }

    var task: Task {
        var params = [ParameterKey: Any]()

        switch target {
        case .activationStatus(let request):
            params[.customerId] = request.customerId
            params[.productInstanceId] = request.productInstanceId
            params[.cardId] = request.cardId
            params[.cardPublicKey] = request.cardPublicKey
        case .getDataToSignByVisaCard(let request):
            params[.customerId] = request.customerId
            params[.productInstanceId] = request.productInstanceId
            params[.activationOrderId] = request.activationOrderId
            params[.customerWalletAddress] = request.customerWalletAddress
        case .getDataToSignByCustomerWallet(let request):
            params[.customerId] = request.customerId
            params[.productInstanceId] = request.productInstanceId
            params[.activationOrderId] = request.activationOrderId
            params[.cardWalletAddress] = request.cardWalletAddress
        case .approveDeployByVisaCard(let request):
            return .requestJSONEncodable(request)
        case .approveDeployByCustomerWallet(let request):
            return .requestJSONEncodable(request)
        case .issuerActivation(let request):
            return .requestJSONEncodable(request)
        }

        return .requestParameters(parameters: params.dictionaryParams, encoding: URLEncoding.default)
    }

    var headers: [String: String]? {
        var params = VisaConstants.defaultHeaderParams
        params[VisaConstants.authorizationHeaderKey] = authorizationToken
        return params
    }
}

extension ProductActivationAPITarget {
    enum Target {
        case activationStatus(request: ActivationStatusRequest)

        case getDataToSignByVisaCard(request: DataToSignByVisaCardRequest)
        case approveDeployByVisaCard(request: VisaCardDeployAcceptanceRequest)

        case getDataToSignByCustomerWallet(request: DataToSignByCustomerWalletRequest)
        case approveDeployByCustomerWallet(request: CustomerWalletDeployAcceptanceRequest)

        case issuerActivation(request: IssuerActivationRequest)
    }
}

private extension ProductActivationAPITarget {
    enum ParameterKey: String {
        case customerId = "customer_id"
        case productInstanceId = "product_instance_id"
        case cardId = "card_id"
        case cardPublicKey = "card_public_key"
        case activationOrderId = "activation_order_id"
        case customerWalletAddress = "customer_wallet_address"
        case cardWalletAddress = "card_wallet_address"
    }
}

private extension Dictionary where Key == ProductActivationAPITarget.ParameterKey, Value == Any {
    var dictionaryParams: [String: Any] {
        var convertedParams = [String: Any]()
        forEach { convertedParams[$0.key.rawValue] = $0.value }
        return convertedParams
    }
}
