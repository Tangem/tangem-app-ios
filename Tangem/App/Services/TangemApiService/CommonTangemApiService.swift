//
//  CommonTangemApiService.swift
//  Tangem
//
//  Created by Alexander Osokin on 21.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Moya
import BlockchainSdk

class CommonTangemApiService {
    private let provider = TangemProvider<TangemApiTarget>(plugins: [
        CachePolicyPlugin(),
        TimeoutIntervalPlugin(),
        NetworkLoggerPlugin(configuration: .init(
            output: NetworkLoggerPlugin.tangemSdkLoggerOutput,
            logOptions: .verbose
        )),
    ])

    private var bag: Set<AnyCancellable> = []

    private let fallbackRegionCode = Locale.current.regionCode?.lowercased() ?? ""
    private var _geoIpRegionCode: String?
    private var authData: TangemApiTarget.AuthData?

    private let coinsQueue = DispatchQueue(label: "coins_request_queue", qos: .default)
    private let currenciesQueue = DispatchQueue(label: "currencies_request_queue", qos: .default)

    deinit {
        AppLog.shared.debug("CommonTangemApiService deinit")
    }

    private func request<D: Decodable>(for type: TangemApiTarget.TargetType) async throws -> D {
        let target = TangemApiTarget(type: type, authData: authData)
        return try await provider.asyncRequest(for: target).mapAPIResponse()
    }
}

// MARK: - TangemApiService

extension CommonTangemApiService: TangemApiService {
    var geoIpRegionCode: String {
        return _geoIpRegionCode ?? fallbackRegionCode
    }

    func loadTokens(for key: String) -> AnyPublisher<UserTokenList, TangemAPIError> {
        let target = TangemApiTarget(type: .getUserWalletTokens(key: key), authData: authData)

        return provider
            .requestPublisher(target)
            .filterSuccessfulStatusCodes()
            .map(UserTokenList.self)
            .mapTangemAPIError()
            .retry(3)
            .eraseToAnyPublisher()
    }

    func saveTokens(list: UserTokenList, for key: String) -> AnyPublisher<Void, TangemAPIError> {
        let target = TangemApiTarget(type: .saveUserWalletTokens(key: key, list: list), authData: authData)

        return provider
            .requestPublisher(target)
            .filterSuccessfulStatusCodes()
            .mapTangemAPIError()
            .mapVoid()
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
                        item.contractAddress?.caseInsensitiveCompare(contractAddress) == .orderedSame
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

    func loadRates(for coinIds: [String]) -> AnyPublisher<[String: Decimal], Error> {
        provider
            .requestPublisher(TangemApiTarget(
                type: .rates(
                    coinIds: coinIds,
                    currencyId: AppSettings.shared.selectedCurrencyCode
                ),
                authData: authData
            ))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(RatesResponse.self)
            .eraseError()
            .map { $0.rates }
            .eraseToAnyPublisher()
    }

    func loadReferralProgramInfo(for userWalletId: String, expectedAwardsLimit: Int) async throws -> ReferralProgramInfo {
        let target = TangemApiTarget(
            type: .loadReferralProgramInfo(userWalletId: userWalletId, expectedAwardsLimit: expectedAwardsLimit),
            authData: authData
        )
        let response = try await provider.asyncRequest(for: target)
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
        let response = try await provider.asyncRequest(for: target)
        let filteredResponse = try response.filterSuccessfulStatusAndRedirectCodes()
        return try JSONDecoder().decode(ReferralProgramInfo.self, from: filteredResponse.data)
    }

    func sales(locale: String, shops: String) async throws -> SalesDetails {
        try await request(for: .sales(locale: locale, shops: shops))
    }

    func promotion(programName: String, timeout: TimeInterval?) async throws -> PromotionParameters {
        try await request(for: .promotion(programName: programName, timeout: timeout))
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

    func initialize() {
        provider
            .requestPublisher(TangemApiTarget(type: .geo, authData: authData))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(GeoResponse.self)
            .map(\.code)
            .replaceError(with: fallbackRegionCode)
            .subscribe(on: DispatchQueue.global())
            .weakAssign(to: \._geoIpRegionCode, on: self)
            .store(in: &bag)

        AppLog.shared.debug("CommonTangemApiService initialized")
    }

    func setAuthData(_ authData: TangemApiTarget.AuthData) {
        self.authData = authData
    }
}

private extension Response {
    func mapAPIResponse<D: Decodable>() throws -> D {
        let filteredResponse = try filterSuccessfulStatusCodes()

        if let baseError = try? filteredResponse.map(TangemBaseAPIError.self) {
            throw baseError.error
        }

        return try filteredResponse.map(D.self)
    }
}
