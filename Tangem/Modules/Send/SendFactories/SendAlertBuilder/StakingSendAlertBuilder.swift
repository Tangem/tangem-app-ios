//
//  StakingSendAlertBuilder.swift
//  TangemApp
//
//  Created by Sergey Balashov on 11.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct StakingSendAlertBuilder: SendAlertBuilder {
    func makeDismissAlert(dismissAction: @escaping () -> Void) -> AlertBinder {
        let dismissButton = Alert.Button.default(Text(Localization.commonYes), action: dismissAction)
        let cancelButton = Alert.Button.cancel(Text(Localization.commonNo))
        return AlertBuilder.makeAlert(
            title: "",
            message: Localization.stakingDismissMessage,
            primaryButton: dismissButton,
            secondaryButton: cancelButton
        )
    }
}
