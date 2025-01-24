//
//  SecurityOptionChangingCardInteractor.swift
//  Tangem
//
//  Created by Alexander Osokin on 29.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

typealias ChangeResult = (Result<Void, Error>) -> Void

class SecurityOptionChangingCardInteractor {
    private let tangemSdk: TangemSdk
    private let cardId: String
    private let canSetLongTap: Bool
    private let canSetAccessCode: Bool
    private let canSetPasscode: Bool
    private var _currentSecurityOption: CurrentValueSubject<SecurityModeOption, Never>

    init(with cardInfo: CardInfo) {
        cardId = cardInfo.card.cardId
        let config = UserWalletConfigFactory(cardInfo).makeConfig()
        canSetLongTap = config.hasFeature(.longTap)
        canSetAccessCode = config.hasFeature(.accessCode)
        canSetPasscode = config.hasFeature(.passcode)
        tangemSdk = config.makeTangemSdk()

        if cardInfo.card.isAccessCodeSet {
            _currentSecurityOption = .init(.accessCode)
        } else if cardInfo.card.isPasscodeSet ?? false {
            _currentSecurityOption = .init(.passCode)
        } else {
            _currentSecurityOption = .init(.longTap)
        }
    }

    private func setAccessCode(_ completion: @escaping ChangeResult) {
        tangemSdk.startSession(
            with: SetUserCodeCommand(accessCode: nil),
            cardId: cardId,
            initialMessage: Message(header: nil, body: Localization.initialMessageChangeAccessCodeBody)
        ) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                Analytics.log(.userCodeChanged)
                _currentSecurityOption.value = .accessCode
                completion(.success(()))
            case .failure(let error):
                Analytics.error(
                    error,
                    params: [
                        .newSecOption: .accessCode,
                        .action: .changeSecOptions,
                    ]
                )
                completion(.failure(error))
            }
        }
    }

    private func setPasscode(_ completion: @escaping ChangeResult) {
        tangemSdk.startSession(
            with: SetUserCodeCommand(passcode: nil),
            cardId: cardId,
            initialMessage: Message(header: nil, body: Localization.initialMessageChangePasscodeBody)
        ) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                _currentSecurityOption.value = .passCode
                completion(.success(()))
            case .failure(let error):
                Analytics.error(
                    error,
                    params: [
                        .newSecOption: .passcode,
                        .action: .changeSecOptions,
                    ]
                )
                completion(.failure(error))
            }
        }
    }

    private func setLongTap(_ completion: @escaping ChangeResult) {
        tangemSdk.startSession(
            with: SetUserCodeCommand.resetUserCodes,
            cardId: cardId
        ) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                _currentSecurityOption.value = .longTap
                completion(.success(()))
            case .failure(let error):
                Analytics.error(
                    error,
                    params: [
                        .newSecOption: .longTap,
                        .action: .changeSecOptions,
                    ]
                )
                completion(.failure(error))
            }
        }
    }
}

// MARK: - SecurityOptionChanging

extension SecurityOptionChangingCardInteractor: SecurityOptionChanging {
    var availableSecurityOptions: [SecurityModeOption] {
        var options: [SecurityModeOption] = []

        if canSetLongTap || _currentSecurityOption.value == .longTap {
            options.append(.longTap)
        }

        if canSetAccessCode || _currentSecurityOption.value == .accessCode {
            options.append(.accessCode)
        }

        if canSetPasscode || _currentSecurityOption.value == .passCode {
            options.append(.passCode)
        }

        return options
    }

    var currentSecurityOption: SecurityModeOption {
        _currentSecurityOption.value
    }

    var currentSecurityOptionPublisher: AnyPublisher<SecurityModeOption, Never> {
        _currentSecurityOption.eraseToAnyPublisher()
    }

    func changeSecurityOption(_ option: SecurityModeOption, completion: @escaping ChangeResult) {
        switch option {
        case .accessCode:
            setAccessCode(completion)
        case .longTap:
            setLongTap(completion)
        case .passCode:
            setPasscode(completion)
        }
    }
}
