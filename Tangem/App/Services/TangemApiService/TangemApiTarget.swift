//
//  TangemApiTarget.swift
//  Tangem
//
//  Created by Andrey Chukavin on 29.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Moya
import TangemSdk

struct TangemApiTarget: TargetType {
    let type: TargetType
    let authData: AuthData?

    var baseURL: URL {
        AppEnvironment.current.apiBaseUrl
    }

    var path: String {
        switch type {
        case .rates:
            return "/rates"
        case .currencies:
            return "/currencies"
        case .coins:
            return "/coins"
        case .geo:
            return "/geo"
        case .getUserWalletTokens(let key), .saveUserWalletTokens(let key, _):
            return "/user-tokens/\(key)"
        case .loadReferralProgramInfo(let userWalletId):
            return "/referral/\(userWalletId)"
        case .participateInReferralProgram:
            return "/referral"
        case .validateNewUserPromotionEligibility:
            return "/promotion/code/validate"
        case .validateOldUserPromotionEligibility:
            return "/promotion/validate"
        case .awardNewUser:
            return "/promotion/code/award"
        case .awardOldUser:
            return "/promotion/award"
        }
    }

    var method: Moya.Method {
        switch type {
        case .rates, .currencies, .coins, .geo, .getUserWalletTokens, .loadReferralProgramInfo:
            return .get
        case .saveUserWalletTokens:
            return .put
        case .participateInReferralProgram, .validateNewUserPromotionEligibility, .validateOldUserPromotionEligibility, .awardNewUser, .awardOldUser:
            return .post
        }
    }

    var task: Task {
        switch type {
        case .rates(let coinIds, let currencyId):
            return .requestParameters(
                parameters: [
                    "coinIds": coinIds.joined(separator: ","),
                    "currencyId": currencyId.lowercased(),
                ],
                encoding: URLEncoding.default
            )
        case .coins(let pageModel):
            return .requestURLEncodable(pageModel)
        case .currencies, .geo, .getUserWalletTokens:
            return .requestPlain
        case .saveUserWalletTokens(_, let list):
            return .requestJSONEncodable(list)
        case .loadReferralProgramInfo:
            return .requestPlain
        case .participateInReferralProgram(let requestData):
            return .requestURLEncodable(requestData)
        case .validateNewUserPromotionEligibility(let walletId, let code):
            return .requestParameters(parameters: [
                "walletId": walletId,
                "code": code,
            ], encoding: JSONEncoding.default)
        case .validateOldUserPromotionEligibility(let walletId, let programName):
            return .requestParameters(parameters: [
                "walletId": walletId,
                "programName": programName,
            ], encoding: JSONEncoding.default)
        case .awardNewUser(let walletId, let address, let code):
            return .requestParameters(parameters: [
                "walletId": walletId,
                "address": address,
                "code": code,
            ], encoding: JSONEncoding.default)
        case .awardOldUser(let walletId, let address, let programName):
            return .requestParameters(parameters: [
                "walletId": walletId,
                "address": address,
                "programName": programName,
            ], encoding: JSONEncoding.default)
        }
    }

    var headers: [String: String]? {
        authData?.headers
    }
}

extension TangemApiTarget {
    enum TargetType {
        case rates(coinIds: [String], currencyId: String)
        case currencies
        case coins(_ requestModel: CoinsListRequestModel)
        case geo
        case getUserWalletTokens(key: String)
        case saveUserWalletTokens(key: String, list: UserTokenList)
        case loadReferralProgramInfo(userWalletId: String)
        case participateInReferralProgram(userInfo: ReferralParticipationRequestBody)

        // Promotion
        case validateNewUserPromotionEligibility(walletId: String, code: String)
        case validateOldUserPromotionEligibility(walletId: String, programName: String)
        case awardNewUser(walletId: String, address: String, code: String)
        case awardOldUser(walletId: String, address: String, programName: String)
    }

    struct AuthData {
        let cardId: String
        let cardPublicKey: Data

        var headers: [String: String] {
            [
                "card_id": cardId,
                "card_public_key": cardPublicKey.hexString,
            ]
        }
    }
}

extension TangemApiTarget: CachePolicyProvider {
    var cachePolicy: URLRequest.CachePolicy {
        switch type {
        case .geo:
            return .reloadIgnoringLocalAndRemoteCacheData
        default:
            return .useProtocolCachePolicy
        }
    }
}
