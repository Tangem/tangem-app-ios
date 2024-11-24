//
//  ExpressAPITarget.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 31.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct ExpressAPITarget: Moya.TargetType {
    let expressAPIType: ExpressAPIType
    let target: Target

    enum Target {
        case assets(request: ExpressDTO.Swap.Assets.Request)
        case pairs(request: ExpressDTO.Swap.Pairs.Request)
        case providers
        case exchangeQuote(request: ExpressDTO.Swap.ExchangeQuote.Request)
        case exchangeData(request: ExpressDTO.Swap.ExchangeData.Request)
        case exchangeStatus(request: ExpressDTO.Swap.ExchangeStatus.Request)
        case exchangeSent(request: ExpressDTO.Swap.ExchangeSent.Request)

        case onrampCurrencies
        case onrampCountries
        case onrampCountryByIP
        case onrampPaymentMethods
        case onrampPairs(request: ExpressDTO.Onramp.Pairs.Request)
        case onrampQuote(request: ExpressDTO.Onramp.Quote.Request)
        case onrampData(request: ExpressDTO.Onramp.Data.Request)
        case onrampStatus(request: ExpressDTO.Onramp.Status.Request)
    }

    var baseURL: URL {
        switch expressAPIType {
        case .develop:
            return URL(string: "https://express.tangem.org/v1/")!
        case .production:
            return URL(string: "https://express.tangem.com/v1/")!
        case .stage:
            return URL(string: "https://express-stage.tangem.com/v1/")!
        }
    }

    var path: String {
        switch target {
        case .assets: "assets"
        case .pairs: "pairs"
        case .providers: "providers"
        case .exchangeQuote: "exchange-quote"
        case .exchangeData: "exchange-data"
        case .exchangeStatus: "exchange-status"
        case .exchangeSent: "exchange-sent"
        case .onrampCurrencies: "currencies"
        case .onrampCountries: "countries"
        case .onrampCountryByIP: "country-by-ip"
        case .onrampPaymentMethods: "payment-methods"
        case .onrampPairs: "onramp-pairs"
        case .onrampQuote: "onramp-quote"
        case .onrampData: "onramp-data"
        case .onrampStatus: "onramp-status"
        }
    }

    var method: Moya.Method {
        switch target {
        case .assets,
             .pairs,
             .exchangeSent,
             .onrampPairs:
            return .post
        case .providers,
             .exchangeQuote,
             .exchangeData,
             .exchangeStatus,
             .onrampCurrencies,
             .onrampCountries,
             .onrampCountryByIP,
             .onrampPaymentMethods,
             .onrampQuote,
             .onrampData,
             .onrampStatus:
            return .get
        }
    }

    var task: Moya.Task {
        switch target {
        case .assets(let request): .requestJSONEncodable(request)
        case .pairs(let request):.requestJSONEncodable(request)
        case .exchangeSent(let request):.requestJSONEncodable(request)
        case .providers:.requestPlain
        case .exchangeQuote(let request):.requestParameters(request)
        case .exchangeData(let request):.requestParameters(request)
        case .exchangeStatus(let request): .requestParameters(request)
        case .onrampCurrencies: .requestPlain
        case .onrampCountries: .requestPlain
        case .onrampCountryByIP: .requestPlain
        case .onrampPaymentMethods: .requestPlain
        case .onrampPairs(let request): .requestJSONEncodable(request)
        case .onrampQuote(let request): .requestParameters(request)
        case .onrampData(let request):.requestParameters(request)
        case .onrampStatus(let request):.requestParameters(request)
        }
    }

    var headers: [String: String]? { nil }
}
