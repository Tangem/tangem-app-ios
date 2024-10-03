//
//  SendFeatureProvider.swift
//  Tangem
//
//  Created by Andrey Chukavin on 14.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class SendFeatureProvider {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    static let shared: SendFeatureProvider = .init()

    var isAvailable: Bool {
        let isSendAvailableRemote = features["send"] ?? true

        return isSendAvailableRemote
    }

    private(set) var features: [String: Bool] = [:]

    private init() {}

    func loadFeaturesAvailability() {
        runTask { [weak self] in
            guard let self else { return }

            features = (try? await tangemApiService.loadFeatures()) ?? [:]
        }
    }
}
