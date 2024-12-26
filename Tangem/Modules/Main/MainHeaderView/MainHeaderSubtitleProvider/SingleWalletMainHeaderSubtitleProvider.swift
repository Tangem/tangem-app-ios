//
//  SingleWalletMainHeaderSubtitleProvider.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SingleWalletMainHeaderSubtitleDataSource: AnyObject {
    var walletDidChangePublisher: AnyPublisher<WalletModel.State, Never> { get }
    var balance: String { get }
}

class SingleWalletMainHeaderSubtitleProvider: MainHeaderSubtitleProvider {
    private weak var dataSource: SingleWalletMainHeaderSubtitleDataSource?

    private let subject: CurrentValueSubject<MainHeaderSubtitleInfo, Never> = .init(.empty)
    private let isLoadingSubject: CurrentValueSubject<Bool, Never>
    private let isUserWalletLocked: Bool

    private var stateUpdateSubscription: AnyCancellable?

    var subtitlePublisher: AnyPublisher<MainHeaderSubtitleInfo, Never> {
        subject.eraseToAnyPublisher()
    }

    var isLoadingPublisher: AnyPublisher<Bool, Never> {
        isLoadingSubject.eraseToAnyPublisher()
    }

    var containsSensitiveInfo: Bool { true }

    init(isUserWalletLocked: Bool, dataSource: SingleWalletMainHeaderSubtitleDataSource?) {
        self.isUserWalletLocked = isUserWalletLocked
        self.dataSource = dataSource
        isLoadingSubject = .init(!isUserWalletLocked)

        initialSetup()
    }

    private func initialSetup() {
        if isUserWalletLocked {
            displayLockedWalletMessage()
        } else {
            bind()
        }
    }

    private func bind() {
        stateUpdateSubscription = dataSource?.walletDidChangePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] newState in
                guard let self else { return }

                if newState == .created || newState == .loading {
                    return
                }

                isLoadingSubject.send(false)

                switch newState {
                case .failed:
                    formatErrorMessage()
                case .loaded, .noAccount:
                    formatBalanceMessage()
                case .created, .loading, .noDerivation:
                    break
                }
            })
    }

    private func formatBalanceMessage() {
        guard let dataSource else { return }

        let balance = dataSource.balance
        subject.send(.init(messages: [balance], formattingOption: .default))
    }

    private func formatErrorMessage() {
        subject.send(.init(messages: [BalanceFormatter.defaultEmptyBalanceString], formattingOption: .default))
    }

    private func displayLockedWalletMessage() {
        subject.send(.init(messages: [Localization.commonLocked], formattingOption: .default))
    }
}

extension WalletModel: SingleWalletMainHeaderSubtitleDataSource {}
