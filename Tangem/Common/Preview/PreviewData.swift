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
            tangemSdk: .init(),
            backupService: .init(sdk: .init()),
            steps: .singleWallet([.createWallet, .success]),
            cardInput: .cardModel(PreviewCard.ethEmptyNote.cardModel),
            twinData: nil
        )
    }

    static var previewTwinOnboardingInput: OnboardingInput {
        .init(
            tangemSdk: .init(),
            backupService: .init(sdk: .init()),
            steps: .twins([
                .intro(pairNumber: "0128"),
                .first,
                .second,
                .third,
                .topup,
                .done,
            ]),
            cardInput: .cardModel(PreviewCard.twin.cardModel),
            twinData: .init(series: TwinCardSeries.cb61)
        )
    }

    static var previewWalletOnboardingInput: OnboardingInput {
        .init(
            tangemSdk: .init(),
            backupService: .init(sdk: .init()),
            steps: .wallet([.createWallet, .backupIntro, .selectBackupCards, .backupCards, .success]),
            cardInput: .cardModel(PreviewCard.tangemWalletEmpty.cardModel),
            twinData: nil
        )
    }
}
