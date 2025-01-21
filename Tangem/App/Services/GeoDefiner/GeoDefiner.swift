//
//  GeoDefiner.swift
//  TangemApp
//
//  Created by Sergey Balashov on 20.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class GeoDefiner: Initializable {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private var _geoIpRegionCode: String?
    private var loadingBag: AnyCancellable?

    public var geoIpRegionCode: String? {
        _geoIpRegionCode ?? Locale.current.regionCode?.lowercased()
    }

    func initialize() {
        loadingBag = tangemApiService
            .loadGeo()
            .subscribe(on: DispatchQueue.global())
            .receiveValue { [weak self] code in
                self?._geoIpRegionCode = code
            }
    }
}
