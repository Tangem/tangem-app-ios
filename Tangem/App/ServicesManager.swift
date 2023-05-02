//
//  ServicesManager.swift
//  Tangem
//
//  Created by Alexander Osokin on 13.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Firebase
import AppsFlyerLib
import Amplitude

class ServicesManager {
    @Injected(\.exchangeService) private var exchangeService: ExchangeService
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private var bag = Set<AnyCancellable>()

    func initialize() {
        AppLog.shared.configure()

        if !AppEnvironment.current.isDebug {
            configureFirebase()
            configureAppsFlyer()
            configureAmplitude()
        }

        let currentLaunches = AppSettings.shared.numberOfLaunches + 1
        AppSettings.shared.numberOfLaunches = currentLaunches
        AppLog.shared.logAppLaunch(currentLaunches)
        S2CTOUMigrator().migrate()

        exchangeService.initialize()
        tangemApiService.initialize()
        userWalletRepository.initialize()
    }

    private func configureFirebase() {
        let plistName = "GoogleService-Info-\(AppEnvironment.current.rawValue.capitalizingFirstLetter())"

        guard let filePath = Bundle.main.path(forResource: plistName, ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: filePath) else {
            assertionFailure("GoogleService-Info.plist not found")
            return
        }

        FirebaseApp.configure(options: options)
    }

    private func configureAppsFlyer() {
        guard AppEnvironment.current.isProduction else {
            return
        }

        do {
            let keysManager = try CommonKeysManager()
            AppsFlyerLib.shared().appsFlyerDevKey = keysManager.appsFlyer.appsFlyerDevKey
            AppsFlyerLib.shared().appleAppID = keysManager.appsFlyer.appsFlyerAppID
        } catch {
            assertionFailure("CommonKeysManager not initialized with error: \(error.localizedDescription)")
        }
    }

    private func configureAmplitude() {
        Amplitude.instance().trackingSessionEvents = true
        Amplitude.instance().initializeApiKey(try! CommonKeysManager().amplitudeApiKey)
    }
}

protocol Initializable {
    func initialize()
}
