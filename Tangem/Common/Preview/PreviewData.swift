//
//  PreviewData.swift
//  Tangem
//
//  Created by Andrew Son on 25.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct PreviewData {
    static var previewNoteCardOnboardingInput: OnboardingInput {
        OnboardingInput(
            backupService: .init(sdk: .init()),
            primaryCardId: "",
            cardInitializer: nil,
            steps: .singleWallet([.createWallet, .success]),
            cardInput: .userWalletModel(PreviewCard.ethEmptyNote.userWalletModel),
            twinData: nil
        )
    }

    static var previewTwinOnboardingInput: OnboardingInput {
        .init(
            backupService: .init(sdk: .init()),
            primaryCardId: "",
            cardInitializer: nil,
            steps: .twins([
                .intro(pairNumber: "0128"),
                .first,
                .second,
                .third,
                .topup,
                .done,
            ]),
            cardInput: .userWalletModel(PreviewCard.twin.userWalletModel),
            twinData: .init(series: TwinCardSeries.cb61)
        )
    }

    static var previewWalletOnboardingInput: OnboardingInput {
        .init(
            backupService: .init(sdk: .init()),
            primaryCardId: "",
            cardInitializer: nil,
            steps: .wallet([.createWallet, .backupIntro, .selectBackupCards, .backupCards, .success]),
            cardInput: .userWalletModel(PreviewCard.tangemWalletEmpty.userWalletModel),
            twinData: nil
        )
    }
}
