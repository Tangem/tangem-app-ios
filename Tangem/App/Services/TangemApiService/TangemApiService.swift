//
//  TangemApiService.swift
//  Tangem
//
//  Created by Alexander Osokin on 21.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol TangemApiService: AnyObject, Initializable {
    // TODO: Refactor https://tangem.atlassian.net/browse/IOS-6869
    var geoIpRegionCode: String { get }

    func loadCoins(requestModel: CoinsList.Request) -> AnyPublisher<[CoinModel], Error>
    func loadQuotes(requestModel: QuotesDTO.Request) -> AnyPublisher<[Quote], Error>
    func loadRates(for coinIds: [String]) -> AnyPublisher<[String: Decimal], Error>
    func loadCurrencies() -> AnyPublisher<[CurrenciesResponse.Currency], Error>

    func loadTokens(for key: String) -> AnyPublisher<UserTokenList?, TangemAPIError>
    func saveTokens(list: UserTokenList, for key: String) -> AnyPublisher<Void, TangemAPIError>

    func createAccount(networkId: String, publicKey: String) -> AnyPublisher<BlockchainAccountCreateResult, TangemAPIError>

    func loadReferralProgramInfo(for userWalletId: String, expectedAwardsLimit: Int) async throws -> ReferralProgramInfo
    func participateInReferralProgram(
        using token: AwardToken,
        for address: String,
        with userWalletId: String
    ) async throws -> ReferralProgramInfo

    func expressPromotion(request: ExpressPromotion.Request) async throws -> ExpressPromotion.Response
    func promotion(programName: String, timeout: TimeInterval?) async throws -> PromotionParameters

    @discardableResult
    func validateNewUserPromotionEligibility(walletId: String, code: String) async throws -> PromotionValidationResult
    @discardableResult
    func validateOldUserPromotionEligibility(walletId: String, programName: String) async throws -> PromotionValidationResult
    @discardableResult
    func awardNewUser(walletId: String, address: String, code: String) async throws -> PromotionAwardResult
    @discardableResult
    func awardOldUser(walletId: String, address: String, programName: String) async throws -> PromotionAwardResult
    @discardableResult
    func resetAwardForCurrentWallet(cardId: String) async throws -> PromotionAwardResetResult

    func loadFeatures() async throws -> [String: Bool]

    // MARK: - Configs

    func loadAPIList() async throws -> APIListDTO

    func setAuthData(_ authData: TangemApiTarget.AuthData)
}

private struct TangemApiServiceKey: InjectionKey {
    static var currentValue: TangemApiService = CommonTangemApiService()
}

extension InjectedValues {
    var tangemApiService: TangemApiService {
        get { Self[TangemApiServiceKey.self] }
        set { Self[TangemApiServiceKey.self] = newValue }
    }
}
