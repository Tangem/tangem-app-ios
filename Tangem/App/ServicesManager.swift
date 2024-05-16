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
import Amplitude
import BlockchainSdk

class ServicesManager {
    @Injected(\.exchangeService) private var exchangeService: ExchangeService
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.accountHealthChecker) private var accountHealthChecker: AccountHealthChecker

    private var bag = Set<AnyCancellable>()

    func initialize() {
        AppLog.shared.configure()

        let initialLaunches = AppSettings.shared.numberOfLaunches
        let currentLaunches = initialLaunches + 1
        AppSettings.shared.numberOfLaunches = currentLaunches

        AppLog.shared.logAppLaunch(currentLaunches)

        if initialLaunches == 0 {
            userWalletRepository.initialClean()
        }

        AppLog.shared.debug("Start services initializing")

        if !AppEnvironment.current.isDebug {
            configureFirebase()
            configureAmplitude()
        }

        configureBlockchainSdkExceptionHandler()

        S2CTOUMigrator().migrate()
        exchangeService.initialize()
        tangemApiService.initialize()
        accountHealthChecker.initialize()
        SendFeatureProvider.shared.loadFeaturesAvailability()
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

    private func configureAmplitude() {
        Amplitude.instance().initializeApiKey(try! CommonKeysManager().amplitudeApiKey)
    }

    private func configureBlockchainSdkExceptionHandler() {
        ExceptionHandler.shared.append(output: Analytics.BlockchainExceptionHandler())
    }
}

protocol Initializable {
    func initialize()
}
