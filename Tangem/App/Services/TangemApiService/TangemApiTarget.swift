//
//  TangemApiTarget.swift
//  Tangem
//
//  Created by Andrey Chukavin on 29.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct TangemApiTarget: TargetType {
    let type: TargetType
    let authData: AuthData?

    // MARK: - TargetType

    var baseURL: URL {
        AppEnvironment.current.apiBaseUrl
    }

    var path: String {
        switch type {
        case .currencies:
            return "/currencies"
        case .coins:
            return "/coins"
        case .quotes:
            return "/quotes"
        case .geo:
            return "/geo"
        case .features:
            return "/features"
        case .getUserWalletTokens(let key), .saveUserWalletTokens(let key, _):
            return "/user-tokens/\(key)"
        case .loadReferralProgramInfo(let userWalletId, _):
            return "/referral/\(userWalletId)"
        case .participateInReferralProgram:
            return "/referral"
        case .promotion:
            return "/promotion"
        case .validateNewUserPromotionEligibility:
            return "/promotion/code/validate"
        case .validateOldUserPromotionEligibility:
            return "/promotion/validate"
        case .awardNewUser:
            return "/promotion/code/award"
        case .awardOldUser:
            return "/promotion/award"
        case .resetAward:
            return "/private/manual-check/promotion-award"
        case .createAccount:
            return "/user-network-account"
        case .apiList:
            return "/networks/providers"

            // MARK: - Markets paths

        case .coinsList:
            return "/coins/list"
        case .coinsHistoryChartPreview:
            return "/coins/history_preview"
        case .tokenMarketsDetails(let requestModel):
            return "/coins/\(requestModel.tokenId)"
        case .historyChart(let requestModel):
            return "/coins/\(requestModel.tokenId)/history"
        case .tokenExchangesList(let requestModel):
            return "/coins/\(requestModel.tokenId)/exchanges"
        }
    }

    var method: Moya.Method {
        switch type {
        case .currencies,
             .coins,
             .quotes,
             .geo,
             .getUserWalletTokens,
             .loadReferralProgramInfo,
             .promotion,
             .apiList,
             .features,
             .coinsList,
             .coinsHistoryChartPreview,
             .tokenMarketsDetails,
             .historyChart,
             .tokenExchangesList:
            return .get
        case .saveUserWalletTokens:
            return .put
        case .participateInReferralProgram,
             .validateNewUserPromotionEligibility,
             .validateOldUserPromotionEligibility,
             .awardNewUser,
             .awardOldUser,
             .createAccount:
            return .post
        case .resetAward:
            return .delete
        }
    }

    var task: Task {
        switch type {
        case .coins(let pageModel):
            return .requestParameters(pageModel)
        case .quotes(let pageModel):
            return .requestParameters(pageModel)
        case .currencies, .geo, .features, .getUserWalletTokens:
            return .requestPlain
        case .saveUserWalletTokens(_, let list):
            return .requestJSONEncodable(list)
        case .loadReferralProgramInfo(_, let expectedAwardsLimit):
            return .requestParameters(
                parameters: [
                    "expected-awards-limit": expectedAwardsLimit,
                ],
                encoding: URLEncoding.default
            )
        case .participateInReferralProgram(let requestData):
            return .requestParameters(requestData)
        case .promotion(let request):
            return .requestParameters(request)
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
        case .resetAward(let cardId):
            return .requestParameters(parameters: [
                "cardId": cardId,
            ], encoding: URLEncoding.default)
        case .createAccount(let parameters):
            return .requestJSONEncodable(parameters)
        case .apiList:
            return .requestPlain

            // MARK: - Markets tasks

        case .coinsList(let requestData):
            return .requestParameters(parameters: requestData.parameters, encoding: URLEncoding.default)
        case .coinsHistoryChartPreview(let requestData):
            return .requestParameters(parameters: requestData.parameters, encoding: URLEncoding(destination: .queryString, arrayEncoding: .noBrackets))
        case .tokenMarketsDetails(let requestModel):
            return .requestParameters(parameters: [
                "currency": requestModel.currency,
                "language": requestModel.language,
            ], encoding: URLEncoding.default)
        case .historyChart(let requestModel):
            return .requestParameters(
                parameters: [
                    "currency": requestModel.currency,
                    "interval": requestModel.interval.historyChartId,
                ],
                encoding: URLEncoding.default
            )
        case .tokenExchangesList:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        var headers: [String: String] = [:]

        if let authData {
            headers["card_id"] = authData.cardId
            headers["card_public_key"] = authData.cardPublicKey.hexString
        }

        if let appVersion: String = InfoDictionaryUtils.version.value() {
            headers["version"] = appVersion
        }

        headers["platform"] = "ios"

        return headers
    }
}

extension TangemApiTarget {
    enum TargetType {
        case currencies
        case coins(_ requestModel: CoinsList.Request)
        case quotes(_ requestModel: QuotesDTO.Request)
        case geo
        case features
        case getUserWalletTokens(key: String)
        case saveUserWalletTokens(key: String, list: UserTokenList)
        case loadReferralProgramInfo(userWalletId: String, expectedAwardsLimit: Int)
        case participateInReferralProgram(userInfo: ReferralParticipationRequestBody)
        case createAccount(_ parameters: BlockchainAccountCreateParameters)

        // Promotion
        case promotion(request: ExpressPromotion.Request)
        case validateNewUserPromotionEligibility(walletId: String, code: String)
        case validateOldUserPromotionEligibility(walletId: String, programName: String)
        case awardNewUser(walletId: String, address: String, code: String)
        case awardOldUser(walletId: String, address: String, programName: String)
        case resetAward(cardId: String)

        // MARK: - Markets Targets

        case coinsList(_ requestModel: MarketsDTO.General.Request)
        case coinsHistoryChartPreview(_ requestModel: MarketsDTO.ChartsHistory.PreviewRequest)
        case tokenMarketsDetails(_ requestModel: MarketsDTO.Coins.Request)
        case historyChart(_ requestModel: MarketsDTO.ChartsHistory.HistoryRequest)
        case tokenExchangesList(_ requestModel: MarketsDTO.ExchangesList.Request)

        // Configs
        case apiList
    }

    struct AuthData {
        let cardId: String
        let cardPublicKey: Data
    }
}

extension TangemApiTarget: CachePolicyProvider {
    var cachePolicy: URLRequest.CachePolicy {
        switch type {
        case .geo, .features, .apiList, .quotes, .coinsList, .tokenMarketsDetails:
            return .reloadIgnoringLocalAndRemoteCacheData
        default:
            return .useProtocolCachePolicy
        }
    }
}

extension TangemApiTarget: TargetTypeLogConvertible {
    var requestDescription: String {
        path
    }

    var shouldLogResponseBody: Bool {
        switch type {
        case .currencies, .coins, .quotes, .apiList, .coinsList, .coinsHistoryChartPreview, .historyChart:
            return false
        case .geo, .features, .getUserWalletTokens, .saveUserWalletTokens, .loadReferralProgramInfo, .participateInReferralProgram, .createAccount, .promotion, .validateNewUserPromotionEligibility, .validateOldUserPromotionEligibility, .awardNewUser, .awardOldUser, .resetAward:
            return true

        // Markets requests
        case .tokenMarketsDetails, .tokenExchangesList:
            return true
        }
    }
}
