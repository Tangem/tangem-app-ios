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

    // MARK: - Coins and quotes

    func loadCoins(requestModel: CoinsList.Request) -> AnyPublisher<[CoinModel], Error>
    func loadQuotes(requestModel: QuotesDTO.Request) -> AnyPublisher<[Quote], Error>
    func loadCurrencies() -> AnyPublisher<[CurrenciesResponse.Currency], Error>

    // Copy loadCoins request via async await
    func loadCoins(requestModel: CoinsList.Request) async throws -> CoinsList.Response

    // MARK: - Markets

    /// Get general market data for a list of tokens
    func loadCoinsList(requestModel: MarketsDTO.General.Request) async throws -> MarketsDTO.General.Response

    func loadTokenMarketsDetails(requestModel: MarketsDTO.Coins.Request) async throws -> MarketsDTO.Coins.Response

    /// Get preview history chart data for a list of tokens
    func loadCoinsHistoryChartPreview(
        requestModel: MarketsDTO.ChartsHistory.PreviewRequest
    ) async throws -> MarketsDTO.ChartsHistory.PreviewResponse

    /// Get detail history chart data for a given token
    func loadHistoryChart(
        requestModel: MarketsDTO.ChartsHistory.HistoryRequest
    ) async throws -> MarketsDTO.ChartsHistory.HistoryResponse

    func loadTokenExchangesListDetails(requestModel: MarketsDTO.ExchangesRequest) async throws -> MarketsDTO.ExchangesResponse

    // MARK: - User token list management

    func loadTokens(for key: String) -> AnyPublisher<UserTokenList?, TangemAPIError>
    func saveTokens(list: UserTokenList, for key: String) -> AnyPublisher<Void, TangemAPIError>

    // MARK: - BSDK

    func createAccount(networkId: String, publicKey: String) -> AnyPublisher<BlockchainAccountCreateResult, TangemAPIError>

    // MARK: - Promotions and awards

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

    // MARK: - Seed Notify

    func getSeedNotifyStatus(userWalletId: String) async throws -> SeedNotifyDTO
    func setSeedNotifyStatus(userWalletId: String, status: SeedNotifyStatus) async throws
    func setWalletInitialized(userWalletId: String) async throws

    // MARK: - Configs

    func loadFeatures() async throws -> [String: Bool]

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
