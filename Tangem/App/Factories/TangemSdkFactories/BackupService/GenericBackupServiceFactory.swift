//
//  GenericBackupServiceFactory.swift
//  Tangem
//
//  Created by Alexander Osokin on 07.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class GenericBackupServiceFactory: BackupServiceFactory {
    private let isAccessCodeSet: Bool

    init(isAccessCodeSet: Bool) {
        self.isAccessCodeSet = isAccessCodeSet
    }

    func makeBackupService() -> BackupService {
        let factory = GenericTangemSdkFactory(isAccessCodeSet: isAccessCodeSet)
        let sdk = factory.makeTangemSdk()
        return BackupService(sdk: sdk)
    }
}
