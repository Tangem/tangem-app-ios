//
//  CommonTangemApiService.swift
//  Tangem
//
//  Created by Alexander Osokin on 21.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import Moya
import BlockchainSdk
import TangemFoundation
import TangemNetworkUtils

class CommonTangemApiService {
    private let provider = TangemProvider<TangemApiTarget>(plugins: [
        CachePolicyPlugin(),
        TimeoutIntervalPlugin(),
        DeviceInfoPlugin(),
        TangemNetworkLoggerPlugin(configuration: .init(
            output: TangemNetworkLoggerPlugin.tangemSdkLoggerOutput,
            logOptions: .verbose
        )),
    ])

    private var bag: Set<AnyCancellable> = []

    private let fallbackRegionCode = Locale.current.regionCode?.lowercased() ?? ""
    private var _geoIpRegionCode: String?
    private var authData: TangemApiTarget.AuthData?

    private let coinsQueue = DispatchQueue(label: "coins_request_queue", qos: .default)
    private let currenciesQueue = DispatchQueue(label: "currencies_request_queue", qos: .default)

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    deinit {
        AppLog.shared.debug("CommonTangemApiService deinit")
    }

    private func request<D: Decodable>(for type: TangemApiTarget.TargetType, decoder: JSONDecoder = .init()) async throws -> D {
        let target = TangemApiTarget(type: type, authData: authData)
        return try await provider.asyncRequest(target).mapAPIResponse(decoder: decoder)
    }
}

// MARK: - TangemApiService

extension CommonTangemApiService: TangemApiService {
    var geoIpRegionCode: String {
        return _geoIpRegionCode ?? fallbackRegionCode
    }

    func loadTokens(for key: String) -> AnyPublisher<UserTokenList?, TangemAPIError> {
        let target = TangemApiTarget(type: .getUserWalletTokens(key: key), authData: authData)

        return provider
            .requestPublisher(target)
            .filterSuccessfulStatusCodes()
            .map(UserTokenList?.self)
            .mapTangemAPIError()
            .catch { error -> AnyPublisher<UserTokenList?, TangemAPIError> in
                if error.code == .notFound {
                    return Just(nil)
                        .setFailureType(to: TangemAPIError.self)
                        .eraseToAnyPublisher()
                }

                return Fail(error: error)
                    .eraseToAnyPublisher()
            }
            .retry(3)
            .eraseToAnyPublisher()
    }

    func saveTokens(list: UserTokenList, for key: String) -> AnyPublisher<Void, TangemAPIError> {
        let target = TangemApiTarget(type: .saveUserWalletTokens(key: key, list: list), authData: authData)

        return provider
            .requestPublisher(target)
            .filterSuccessfulStatusCodes()
            .mapTangemAPIError()
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    func createAccount(networkId: String, publicKey: String) -> AnyPublisher<BlockchainAccountCreateResult, TangemAPIError> {
        let parameters = BlockchainAccountCreateParameters(networkId: networkId, walletPublicKey: publicKey)
        let target = TangemApiTarget(type: .createAccount(parameters), authData: authData)

        return provider
            .requestPublisher(target)
            .filterSuccessfulStatusCodes()
            .map(BlockchainAccountCreateResult.self)
            .mapTangemAPIError()
            .eraseToAnyPublisher()
    }

    func loadCoins(requestModel: CoinsList.Request) -> AnyPublisher<[CoinModel], Error> {
        provider
            .requestPublisher(TangemApiTarget(type: .coins(requestModel), authData: authData))
            .filterSuccessfulStatusCodes()
            .map(CoinsList.Response.self)
            .eraseError()
            .map { response in
                let mapper = CoinsResponseMapper(supportedBlockchains: requestModel.supportedBlockchains)
                let coinModels = mapper.mapToCoinModels(response)

                guard let contractAddress = requestModel.contractAddress else {
                    return coinModels
                }

                return coinModels.compactMap { coinModel in
                    let items = coinModel.items.filter { item in
                        item.token?.contractAddress.caseInsensitiveCompare(contractAddress) == .orderedSame
                    }

                    guard !items.isEmpty else {
                        return nil
                    }

                    return CoinModel(
                        id: coinModel.id,
                        name: coinModel.name,
                        symbol: coinModel.symbol,
                        items: items
                    )
                }
            }
            .subscribe(on: coinsQueue)
            .eraseToAnyPublisher()
    }

    func loadCoins(requestModel: CoinsList.Request) async throws -> CoinsList.Response {
        return try await request(for: .coins(requestModel), decoder: decoder)
    }

    func loadQuotes(requestModel: QuotesDTO.Request) -> AnyPublisher<[Quote], Error> {
        let target = TangemApiTarget(type: .quotes(requestModel), authData: authData)

        return provider
            .requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(QuotesDTO.Response.self)
            .eraseError()
            .map { response in
                QuotesMapper().mapToQuotes(response)
            }
            .eraseToAnyPublisher()
    }

    func loadCurrencies() -> AnyPublisher<[CurrenciesResponse.Currency], Error> {
        provider
            .requestPublisher(TangemApiTarget(type: .currencies, authData: authData))
            .filterSuccessfulStatusCodes()
            .map(CurrenciesResponse.self)
            .map { $0.currencies.sorted(by: { $0.name < $1.name }) }
            .mapError { _ in AppError.serverUnavailable }
            .subscribe(on: currenciesQueue)
            .eraseToAnyPublisher()
    }

    func loadReferralProgramInfo(for userWalletId: String, expectedAwardsLimit: Int) async throws -> ReferralProgramInfo {
        let target = TangemApiTarget(
            type: .loadReferralProgramInfo(userWalletId: userWalletId, expectedAwardsLimit: expectedAwardsLimit),
            authData: authData
        )
        let response = try await provider.asyncRequest(target)
        let filteredResponse = try response.filterSuccessfulStatusAndRedirectCodes()
        return try JSONDecoder().decode(ReferralProgramInfo.self, from: filteredResponse.data)
    }

    func participateInReferralProgram(
        using token: AwardToken,
        for address: String,
        with userWalletId: String
    ) async throws -> ReferralProgramInfo {
        let userInfo = ReferralParticipationRequestBody(
            walletId: userWalletId,
            networkId: token.networkId,
            tokenId: token.id,
            address: address
        )
        let target = TangemApiTarget(
            type: .participateInReferralProgram(userInfo: userInfo),
            authData: authData
        )
        let response = try await provider.asyncRequest(target)
        let filteredResponse = try response.filterSuccessfulStatusAndRedirectCodes()
        return try JSONDecoder().decode(ReferralProgramInfo.self, from: filteredResponse.data)
    }

    func expressPromotion(request model: ExpressPromotion.Request) async throws -> ExpressPromotion.Response {
        return try await request(for: .promotion(request: model), decoder: decoder)
    }

    func promotion(programName: String, timeout: TimeInterval?) async throws -> PromotionParameters {
        try await request(for: .promotion(request: .init(programName: programName)))
    }

    @discardableResult
    func validateNewUserPromotionEligibility(walletId: String, code: String) async throws -> PromotionValidationResult {
        try await request(for: .validateNewUserPromotionEligibility(walletId: walletId, code: code))
    }

    @discardableResult
    func validateOldUserPromotionEligibility(walletId: String, programName: String) async throws -> PromotionValidationResult {
        try await request(for: .validateOldUserPromotionEligibility(walletId: walletId, programName: programName))
    }

    @discardableResult
    func awardNewUser(walletId: String, address: String, code: String) async throws -> PromotionAwardResult {
        try await request(for: .awardNewUser(walletId: walletId, address: address, code: code))
    }

    @discardableResult
    func awardOldUser(walletId: String, address: String, programName: String) async throws -> PromotionAwardResult {
        try await request(for: .awardOldUser(walletId: walletId, address: address, programName: programName))
    }

    @discardableResult
    func resetAwardForCurrentWallet(cardId: String) async throws -> PromotionAwardResetResult {
        try await request(for: .resetAward(cardId: cardId))
    }

    func loadAPIList() async throws -> APIListDTO {
        try await request(for: .apiList)
    }

    func loadFeatures() async throws -> [String: Bool] {
        try await request(for: .features)
    }

    // MARK: - Markets Implementation

    func loadCoinsList(requestModel: MarketsDTO.General.Request) async throws -> MarketsDTO.General.Response {
        return try await request(for: .coinsList(requestModel), decoder: decoder)
    }

    func loadCoinsHistoryChartPreview(
        requestModel: MarketsDTO.ChartsHistory.PreviewRequest
    ) async throws -> MarketsDTO.ChartsHistory.PreviewResponse {
        return try await request(for: .coinsHistoryChartPreview(requestModel), decoder: decoder)
    }

    func loadTokenMarketsDetails(requestModel: MarketsDTO.Coins.Request) async throws -> MarketsDTO.Coins.Response {
        return try await request(for: .tokenMarketsDetails(requestModel), decoder: decoder)
    }

    func loadHistoryChart(
        requestModel: MarketsDTO.ChartsHistory.HistoryRequest
    ) async throws -> MarketsDTO.ChartsHistory.HistoryResponse {
        return try await request(for: .historyChart(requestModel), decoder: decoder)
    }

    func loadTokenExchangesListDetails(
        requestModel: MarketsDTO.ExchangesRequest
    ) async throws -> MarketsDTO.ExchangesResponse {
        return try await request(for: .tokenExchangesList(requestModel), decoder: decoder)
    }

    // MARK: - Action Buttons

    func loadHotCrypto(requestModel: HotCryptoDTO.Request) async throws -> HotCryptoDTO.Response {
        try await request(for: .hotCrypto(requestModel))
    }

    func getSeedNotifyStatus(userWalletId: String) async throws -> SeedNotifyDTO {
        return try await request(for: .seedNotifyGetStatus(userWalletId: userWalletId), decoder: decoder)
    }

    func setSeedNotifyStatus(userWalletId: String, status: SeedNotifyStatus) async throws {
        let target = TangemApiTarget(type: .seedNotifySetStatus(userWalletId: userWalletId, status: status), authData: authData)
        _ = try await provider.asyncRequest(target)
    }

    func setWalletInitialized(userWalletId: String) async throws {
        let target = TangemApiTarget(type: .walletInitialized(userWalletId: userWalletId), authData: authData)
        _ = try await provider.asyncRequest(target)
    }

    // MARK: - Init

    func initialize() {
        provider
            .requestPublisher(TangemApiTarget(type: .geo, authData: authData))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(GeoResponse.self)
            .map(\.code)
            .eraseToOptional()
            .replaceError(with: fallbackRegionCode)
            .subscribe(on: DispatchQueue.global())
            .assign(to: \._geoIpRegionCode, on: self, ownership: .weak)
            .store(in: &bag)

        AppLog.shared.debug("CommonTangemApiService initialized")
    }

    func setAuthData(_ authData: TangemApiTarget.AuthData) {
        self.authData = authData
    }
}

private extension Response {
    func mapAPIResponse<D: Decodable>(decoder: JSONDecoder = .init()) throws -> D {
        let filteredResponse = try filterSuccessfulStatusCodes()

        if let baseError = try? filteredResponse.map(TangemBaseAPIError.self) {
            throw baseError.error
        }

        return try filteredResponse.map(D.self, using: decoder)
    }
}
