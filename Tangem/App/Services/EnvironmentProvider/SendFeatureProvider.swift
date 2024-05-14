//
//  SendFeatureProvider.swift
//  Tangem
//
//  Created by Andrey Chukavin on 14.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

#warning("TODO: remove with LegacySendViewModel")
enum SendFeatureProvider {
    @Injected(\.tangemApiService) private static var tangemApiService: TangemApiService

    static var isAvailable: Bool {
        FeatureProvider.isAvailable(.sendV2) && tangemApiService.features["send"] == true
    }
}
