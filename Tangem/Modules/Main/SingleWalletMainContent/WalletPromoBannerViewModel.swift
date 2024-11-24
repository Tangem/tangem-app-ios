//
//  Untitled.swift
//  TangemApp
//
//  Created by Alexander Osokin on 14.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class WalletPromoBannerViewModel: ObservableObject {
    private let currencySymbol: String
    private let tokenRouter: SingleTokenRoutable

    init(currencySymbol: String, tokenRouter: SingleTokenRoutable) {
        self.currencySymbol = currencySymbol
        self.tokenRouter = tokenRouter
    }

    func onAppear() {
        Analytics.log(event: .walletPromoAppear, params: [
            .token: currencySymbol,
        ])
    }

    func didTapWalletPromo() {
        Analytics.log(event: .walletPromoButtonClicked, params: [
            .token: currencySymbol,
        ])

        tokenRouter.openInSafari(url: Constants.url)
    }
}

private extension WalletPromoBannerViewModel {
    enum Constants {
        static let url = URL(string: "https://tangem.com/en/?promocode=Note10")!
    }
}
