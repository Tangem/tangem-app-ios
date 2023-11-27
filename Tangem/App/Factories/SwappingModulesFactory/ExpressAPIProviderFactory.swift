//
//  ExpressAPIProviderFactory.swift
//  Tangem
//
//  Created by Andrew Son on 24/11/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemSwapping

struct CommonExpressAPIFactory {
    @Injected(\.keysManager) private var keysManager: KeysManager

    func makeExpressAPIProvider() -> ExpressAPIProvider {
        let factory = TangemSwappingFactory()
        let credentials = ExpressAPICredential(
            apiKey: keysManager.tangemExpressApiKey,
            userId: UUID().uuidString,
            sessionId: UUID().uuidString
        )

        return factory.makeExpressAPIProvider(
            credential: credentials,
            configuration: .defaultConfiguration,
            logger: AppLog.shared
        )
    }
}
