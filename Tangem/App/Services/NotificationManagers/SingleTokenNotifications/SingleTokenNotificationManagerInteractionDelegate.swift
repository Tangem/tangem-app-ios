//
//  SingleTokenNotificationManagerInteractionDelegate.swift
//  Tangem
//
//  Created by Andrey Fedorov on 19.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol SingleTokenNotificationManagerInteractionDelegate: AnyObject {
    func confirmDiscardingUnfulfilledAssetRequirements(
        with configuration: TokenNotificationEvent.UnfulfilledRequirementsConfiguration,
        confirmationAction: @escaping () -> Void
    )
}
