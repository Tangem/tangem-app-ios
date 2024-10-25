//
//  ExpressAPIProviderFactory.swift
//  Tangem
//
//  Created by Andrew Son on 24/11/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemExpress

struct ExpressAPIProviderFactory {
    @Injected(\.keysManager) private var keysManager: KeysManager

    func makeExpressAPIProvider(userId: String, logger: Logger) -> ExpressAPIProvider {
        let factory = TangemExpressFactory()
        let expressAPIType: ExpressAPIType = {
            if AppEnvironment.current.isProduction {
                return .production
            }

            return ExpressAPIType(rawValue: FeatureStorage().apiExpress) ?? .production
        }()

        let apiKey = apiKey(expressAPIType: expressAPIType)
        let publicKey = signVerifierPublicKey(expressAPIType: expressAPIType)
        let exchangeDataDecoder = CommonExpressExchangeDataDecoder(publicKey: publicKey)

        let containsRing = AppSettings.shared.userWalletIdsWithRing.contains(userId)
        let refcode = containsRing ? Refcodes.ring.rawValue : nil

        let credentials = ExpressAPICredential(
            apiKey: apiKey,
            userId: userId,
            sessionId: AppConstants.sessionId,
            refcode: refcode
        )

        let deviceInfo = ExpressDeviceInfo(
            platform: AppConstants.platformName.lowercased(),
            version: appVersion()
        )

        return factory.makeExpressAPIProvider(
            credential: credentials,
            deviceInfo: deviceInfo,
            configuration: .defaultConfiguration,
            expressAPIType: expressAPIType,
            exchangeDataDecoder: exchangeDataDecoder,
            logger: AppLog.shared
        )
    }
}

private extension ExpressAPIProviderFactory {
    func apiKey(expressAPIType: ExpressAPIType) -> String {
        switch expressAPIType {
        case .develop, .stage:
            if let apiKey = keysManager.devExpressKeys?.apiKey {
                return apiKey
            }

            assertionFailure("[Express] ApiKey not found")
            return ""
        case .production:
            return keysManager.expressKeys.apiKey
        }
    }

    func signVerifierPublicKey(expressAPIType: ExpressAPIType) -> String {
        switch expressAPIType {
        case .develop, .stage:
            if let publicKey = keysManager.devExpressKeys?.signVerifierPublicKey {
                return publicKey
            }

            assertionFailure("[Express] SignVerifierPublicKey not found")
            return ""
        case .production:
            return keysManager.expressKeys.signVerifierPublicKey
        }
    }

    func appVersion() -> String {
        if let appVersion: String = InfoDictionaryUtils.version.value() {
            return appVersion
        }

        assertionFailure("Can't get the app version from the app bundle")
        return .unknown.lowercased()
    }
}

private extension ExpressAPIProviderFactory {
    enum Refcodes: String {
        case ring
    }
}
