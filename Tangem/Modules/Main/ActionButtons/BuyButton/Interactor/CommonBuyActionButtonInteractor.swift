//
//  CommonBuyActionButtonInteractor.swift
//  TangemApp
//
//  Created by GuitarKitty on 06.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

protocol BuyActionButtonInteractor {
    var isBuyAvailable: Bool { get }
}

final class CommonBuyActionButtonInteractor: BuyActionButtonInteractor {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    var isBuyAvailable: Bool {
        tangemApiService.geoIpRegionCode != LanguageCode.ru
    }
}
