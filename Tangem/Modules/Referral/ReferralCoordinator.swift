//
//  ReferralCoordinator.swift
//  Tangem
//
//  Created by Andrew Son on 02/11/22.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

class ReferralCoordinator: CoordinatorObject {
    var dismissAction: Action
    var popToRootAction: ParamsAction<PopToRootOptions>

    @Published var referralViewModel: ReferralViewModel? = nil
    @Published var tosViewModel: WebViewContainerViewModel? = nil

    required init(dismissAction: @escaping Action, popToRootAction: @escaping ParamsAction<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        referralViewModel = .init(
            userWalletId: options.userWalletId,
            supportedBlockchains: options.supportedBlockchains,
            userTokensManager: options.userTokensManager,
            coordinator: self
        )
    }
}

extension ReferralCoordinator {
    struct Options {
        let userWalletId: Data
        let supportedBlockchains: Set<Blockchain>
        let userTokensManager: UserTokensManager
    }
}

extension ReferralCoordinator: ReferralRoutable {
    func openTOS(with url: URL) {
        tosViewModel = WebViewContainerViewModel(
            url: url,
            title: Localization.detailsReferralTitle
        )
    }
}
