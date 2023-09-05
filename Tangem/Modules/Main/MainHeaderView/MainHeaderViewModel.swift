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
    let cardImage: ImageType?
    let isUserWalletLocked: Bool

    @Published private(set) var userWalletName: String = ""
    @Published private(set) var subtitleInfo: MainHeaderSubtitleInfo = .empty
    @Published private(set) var balance: NSAttributedString = .init(string: "")
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
        cardImage = infoProvider.cardHeaderImage
        bind()
    }

    private func bind() {
        infoProvider.userWalletNamePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.userWalletName, on: self, ownership: .weak)
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
            .sink { [weak self] newValue in
                if self?.infoProvider.isUserWalletLocked ?? false {
                    return
                }

                switch newValue {
                case .loading:
                    self?.isLoadingFiatBalance = true
                case .loaded(let balance):
                    self?.isLoadingFiatBalance = false

                    let balanceFormatter = BalanceFormatter()
                    let fiatBalanceFormatted = balanceFormatter.formatFiatBalance(balance.balance, formattingOptions: .defaultFiatFormattingOptions)
                    self?.balance = balanceFormatter.formatTotalBalanceForMain(fiatBalance: fiatBalanceFormatted, formattingOptions: .defaultOptions)
                case .failedToLoad(let error):
                    AppLog.shared.debug("Failed to load total balance. Reason: \(error)")
                    self?.isLoadingFiatBalance = false

                    self?.balance = NSAttributedString(string: BalanceFormatter.defaultEmptyBalanceString)
                }
            }
            .store(in: &bag)
    }
}
