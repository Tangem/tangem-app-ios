//
//  OnrampRoutable.swift
//  TangemApp
//
//  Created by Sergey Balashov on 25.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemExpress

protocol OnrampRoutable {
    func openOnrampCountry(country: OnrampCountry, repository: OnrampRepository)
    func openOnrampCountrySelector(repository: OnrampRepository, dataRepository: OnrampDataRepository)
    func openOnrampCurrencySelectorView(repository: OnrampRepository, dataRepository: OnrampDataRepository)

    func openOnrampProviders()
}
