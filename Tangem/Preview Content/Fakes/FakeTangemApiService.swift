//
//  FakeTangemApiService.swift
//  Tangem
//
//  Created by Andrew Son on 14/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class FakeTangemApiService: TangemApiService {
    var geoIpRegionCode: String

    init(geoIpRegionCode: String = "us") {
        self.geoIpRegionCode = geoIpRegionCode
    }

    func loadCoins(requestModel: CoinsList.Request) -> AnyPublisher<[CoinModel], Error> {
        .anyFail(error: "Not implemented")
    }

    func loadQuotes(requestModel: QuotesDTO.Request) -> AnyPublisher<[Quote], Error> {
        .anyFail(error: "Not implemented")
    }

    func loadRates(for coinIds: [String]) -> AnyPublisher<[String: Decimal], Error> {
        .anyFail(error: "Not implemented")
    }

    func loadCurrencies() -> AnyPublisher<[CurrenciesResponse.Currency], Error> {
        .anyFail(error: "Not implemented")
    }

    func loadTokens(for key: String) -> AnyPublisher<UserTokenList, TangemAPIError> {
        .anyFail(error: .init(code: .notFound))
    }

    func saveTokens(list: UserTokenList, for key: String) -> AnyPublisher<Void, TangemAPIError> {
        .anyFail(error: .init(code: .notFound))
    }

    func loadReferralProgramInfo(for userWalletId: String, expectedAwardsLimit: Int) async throws -> ReferralProgramInfo {
        throw "Not implemented"
    }

    func participateInReferralProgram(using token: AwardToken, for address: String, with userWalletId: String) async throws -> ReferralProgramInfo {
        throw "Not implemented"
    }

    func sales(locale: String, shops: String) async throws -> SalesDetails {
        throw "Not implemented"
    }

    func promotion(programName: String, timeout: TimeInterval?) async throws -> PromotionParameters {
        throw "Not implemented"
    }

    func validateNewUserPromotionEligibility(walletId: String, code: String) async throws -> PromotionValidationResult {
        throw "Not implemented"
    }

    func validateOldUserPromotionEligibility(walletId: String, programName: String) async throws -> PromotionValidationResult {
        throw "Not implemented"
    }

    func awardNewUser(walletId: String, address: String, code: String) async throws -> PromotionAwardResult {
        throw "Not implemented"
    }

    func awardOldUser(walletId: String, address: String, programName: String) async throws -> PromotionAwardResult {
        throw "Not implemented"
    }

    func resetAwardForCurrentWallet(cardId: String) async throws -> PromotionAwardResetResult {
        throw "Not implemented"
    }

    func setAuthData(_ authData: TangemApiTarget.AuthData) {}

    func initialize() {}
}
