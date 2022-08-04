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

class CommonTangemApiService {
    @Injected(\.cardsRepository) var cardsRepository: CardsRepository

    private let provider = TangemProvider<TangemApiTarget>()
    private var bag: Set<AnyCancellable> = .init()

    private let fallbackRegionCode = Locale.current.regionCode?.lowercased() ?? ""
    private var _geoIpRegionCode: String? = nil
    private var authData: TangemApiTarget.AuthData? = nil

    deinit {
        print("CommonTangemApiService deinit")
    }
}

extension CommonTangemApiService: TangemApiService {
    var geoIpRegionCode: String {
        return _geoIpRegionCode ?? fallbackRegionCode
    }

    func loadCoins(requestModel: CoinsListRequestModel) -> AnyPublisher<[CoinModel], Error> {
        provider
            .requestPublisher(TangemApiTarget(type: .coins(requestModel), authData: authData))
            .filterSuccessfulStatusCodes()
            .map(CoinsResponse.self)
            .eraseError()
            .map { list -> [CoinModel] in
                list.coins.map { CoinModel(with: $0, baseImageURL: list.imageHost) }
            }
            .map { coinModels in
                guard let contractAddress = requestModel.contractAddress else {
                    return coinModels
                }

                return coinModels.compactMap { coinModel in
                    let items = coinModel.items.filter {
                        let itemContractAddress = $0.contractAddress ?? ""
                        return itemContractAddress.caseInsensitiveCompare(contractAddress) == .orderedSame
                    }

                    guard !items.isEmpty else {
                        return nil
                    }

                    return CoinModel(
                        id: coinModel.id,
                        name: coinModel.name,
                        symbol: coinModel.symbol,
                        imageURL: coinModel.imageURL,
                        items: items
                    )
                }
            }
            .subscribe(on: DispatchQueue.global())
            .eraseToAnyPublisher()
    }

    func loadCurrencies() -> AnyPublisher<[CurrenciesResponse.Currency], Error> {
        provider
            .requestPublisher(TangemApiTarget(type: .currencies, authData: authData))
            .filterSuccessfulStatusCodes()
            .map(CurrenciesResponse.self)
            .map { $0.currencies.sorted(by: { $0.name < $1.name }) }
            .mapError { _ in AppError.serverUnavailable }
            .subscribe(on: DispatchQueue.global())
            .eraseToAnyPublisher()
    }

    func loadRates(for coinIds: [String], currencyCode: String) -> AnyPublisher<[String: Decimal], Never> {
        provider
            .requestPublisher(TangemApiTarget(type: .rates(coinIds: coinIds, currencyId: currencyCode),
                                              authData: authData))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(RatesResponse.self)
            .map { $0.rates }
            .catch { _ in Empty(completeImmediately: true) }
            .subscribe(on: DispatchQueue.global())
            .eraseToAnyPublisher()
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
    }

    func setAuthData(_ authData: TangemApiTarget.AuthData) {
        self.authData = authData
    }
}
