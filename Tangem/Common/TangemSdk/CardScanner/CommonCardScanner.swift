//
//  CommonCardScanner.swift
//  Tangem
//
//  Created by Alexander Osokin on 11.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemSdk

class CommonCardScanner: CardScanner {
    private let tangemSdk: TangemSdk
    private let parameters: CardScannerParameters
    private var cancellable: AnyCancellable?

    init(tangemSdk: TangemSdk, parameters: CardScannerParameters) {
        self.tangemSdk = tangemSdk
        self.parameters = parameters
    }

    // Make default scanner
    convenience init() {
        var config = TangemSdkConfigFactory().makeDefaultConfig()

        if AppSettings.shared.saveUserWallets {
            config.accessCodeRequestPolicy = .alwaysWithBiometrics
        }

        let scannerParameters = CardScannerParameters(
            shouldAskForAccessCodes: false,
            performDerivations: true,
            sessionFilter: nil
        )

        let sdk = TangemSdkDefaultFactory().makeTangemSdk(with: config)
        self.init(tangemSdk: sdk, parameters: scannerParameters)
    }

    func scanCardPublisher() -> AnyPublisher<AppScanTaskResponse, TangemSdkError> {
        let task = AppScanTask(
            shouldAskForAccessCode: parameters.shouldAskForAccessCodes,
            performDerivations: parameters.performDerivations
        )

        let didBecomeActivePublisher = NotificationCenter.didBecomeActivePublisher
            .mapError { $0.toTangemSdkError() }
            .mapToVoid()
            .first()

        return tangemSdk.startSessionPublisher(with: task, filter: parameters.sessionFilter)
            .combineLatest(didBecomeActivePublisher)
            .map { $0.0 }
            .handleEvents(receiveCompletion: { _ in
                withExtendedLifetime(task) {}
            })
            .eraseToAnyPublisher()
    }

    func scanCard(completion: @escaping (Result<AppScanTaskResponse, TangemSdkError>) -> Void) {
        cancellable = scanCardPublisher()
            .sink(receiveCompletion: { [weak self] completionResult in
                switch completionResult {
                case .finished:
                    break
                case .failure(let error):
                    completion(.failure(error))
                }

                self?.cancellable = nil
            }, receiveValue: {
                completion(.success($0))
            })
    }
}
