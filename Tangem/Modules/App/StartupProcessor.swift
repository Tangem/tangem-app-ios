//
//  StartupProcessor.swift
//  Tangem
//
//  Created by Alexander Osokin on 22.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class StartupProcessor {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    func getStartupOption() -> StartupOption {
        if BackupHelper().hasIncompletedBackup {
            return .uncompletedBackup
        }

        if AppSettings.shared.saveUserWallets,
           !userWalletRepository.isEmpty,
           BiometricsUtil.isAvailable {
            return .auth
        }

        return .welcome
    }
}

enum StartupOption {
    case uncompletedBackup
    case auth
    case welcome
}
