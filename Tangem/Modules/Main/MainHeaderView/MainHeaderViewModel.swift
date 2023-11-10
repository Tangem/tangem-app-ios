//
//  MainHeaderViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 10/05/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class MainHeaderViewModel: ObservableObject {
    let isUserWalletLocked: Bool

    @Published private(set) var cardImage: ImageType?
    @Published private(set) var userWalletName: String = ""
    @Published private(set) var subtitleInfo: MainHeaderSubtitleInfo = .empty
    @Published private(set) var balance: NSAttributedString = .init(string: BalanceFormatter.defaultEmptyBalanceString)
    @Published var isLoadingFiatBalance: Bool = true
    @Published var isLoadingSubtitle: Bool = true

    var subtitleContainsSensitiveInfo: Bool {
        subtitleProvider.containsSensitiveInfo
    }

    private let infoProvider: MainHeaderInfoProvider
    private let subtitleProvider: MainHeaderSubtitleProvider
    private let balanceProvider: TotalBalanceProviding

    private var bag: Set<AnyCancellable> = []

    init(
        infoProvider: MainHeaderInfoProvider,
        subtitleProvider: MainHeaderSubtitleProvider,
        balanceProvider: TotalBalanceProviding
    ) {
        self.infoProvider = infoProvider
        self.subtitleProvider = subtitleProvider
        self.balanceProvider = balanceProvider

        isUserWalletLocked = infoProvider.isUserWalletLocked
        bind()
    }

    private func bind() {
        infoProvider.userWalletNamePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.userWalletName, on: self, ownership: .weak)
            .store(in: &bag)

        infoProvider.cardHeaderImagePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.cardImage, on: self, ownership: .weak)
            .store(in: &bag)

        subtitleProvider.isLoadingPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoadingSubtitle, on: self, ownership: .weak)
            .store(in: &bag)

        subtitleProvider.subtitlePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.subtitleInfo, on: self, ownership: .weak)
            .store(in: &bag)

        balanceProvider.totalBalancePublisher()
            .receive(on: DispatchQueue.main)
            .debounce(for: 0.2, scheduler: DispatchQueue.main) // Hide skeleton and apply state with delay, mimic current behavior
            .sink { [weak self] newValue in
                guard let self else {
                    return
                }

                if infoProvider.isUserWalletLocked {
                    return
                }

                switch newValue {
                case .loading:
                    isLoadingFiatBalance = true
                case .loaded(let balance):
                    isLoadingFiatBalance = false

                    let balanceFormatter = BalanceFormatter()
                    var balanceToFormat = balance.balance
                    if balanceToFormat == nil, infoProvider.isTokensListEmpty {
                        balanceToFormat = 0
                    }
                    let fiatBalanceFormatted = balanceFormatter.formatFiatBalance(balanceToFormat, formattingOptions: .defaultFiatFormattingOptions)
                    self.balance = balanceFormatter.formatTotalBalanceForMain(fiatBalance: fiatBalanceFormatted, formattingOptions: .defaultOptions)
                case .failedToLoad(let error):
                    AppLog.shared.debug("Failed to load total balance. Reason: \(error)")
                    isLoadingFiatBalance = false

                    balance = NSAttributedString(string: BalanceFormatter.defaultEmptyBalanceString)
                }
            }
            .store(in: &bag)
    }
}
