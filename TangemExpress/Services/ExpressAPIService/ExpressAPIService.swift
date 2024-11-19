//
//  ExpressAPIService.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 31.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya

protocol ExpressAPIService {
    func assets(request: ExpressDTO.Swap.Assets.Request) async throws -> [ExpressDTO.Swap.Assets.Response]
    func pairs(request: ExpressDTO.Swap.Pairs.Request) async throws -> [ExpressDTO.Swap.Pairs.Response]
    func providers() async throws -> [ExpressDTO.Swap.Providers.Response]
    func exchangeQuote(request: ExpressDTO.Swap.ExchangeQuote.Request) async throws -> ExpressDTO.Swap.ExchangeQuote.Response
    func exchangeData(request: ExpressDTO.Swap.ExchangeData.Request) async throws -> ExpressDTO.Swap.ExchangeData.Response
    func exchangeStatus(request: ExpressDTO.Swap.ExchangeStatus.Request) async throws -> ExpressDTO.Swap.ExchangeStatus.Response
    func exchangeSent(request: ExpressDTO.Swap.ExchangeSent.Request) async throws -> ExpressDTO.Swap.ExchangeSent.Response

    func onrampCurrencies() async throws -> [ExpressDTO.Onramp.FiatCurrency]
    func onrampCountries() async throws -> [ExpressDTO.Onramp.Country]
    func onrampCountryByIP() async throws -> ExpressDTO.Onramp.Country
    func onrampPaymentMethods() async throws -> [ExpressDTO.Onramp.PaymentMethod]
    func onrampPairs(request: ExpressDTO.Onramp.Pairs.Request) async throws -> [ExpressDTO.Onramp.Pairs.Response]
    func onrampQuote(request: ExpressDTO.Onramp.Quote.Request) async throws -> ExpressDTO.Onramp.Quote.Response
    func onrampData(request: ExpressDTO.Onramp.Data.Request) async throws -> ExpressDTO.Onramp.Data.Response
    func onrampStatus(request: ExpressDTO.Onramp.Status.Request) async throws -> ExpressDTO.Onramp.Status.Response
}
