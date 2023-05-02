//
//  TwinTangemSdkFactory.swift
//  Tangem
//
//  Created by Alexander Osokin on 07.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class TwinTangemSdkFactory: TangemSdkFactory {
    private let isAccessCodeSet: Bool

    init(isAccessCodeSet: Bool) {
        self.isAccessCodeSet = isAccessCodeSet
    }

    func makeTangemSdk() -> TangemSdk {
        var config = TangemSdkConfigFactory().makeDefaultConfig()
        config.accessCodeRequestPolicy = AccessCodeRequestPolicyFactory().makePolicy(isAccessCodeSet: isAccessCodeSet)
        config.cardIdDisplayFormat = .lastLunh(4)
        let sdk = TangemSdkDefaultFactory().makeTangemSdk(with: config)
        return sdk
    }
}
