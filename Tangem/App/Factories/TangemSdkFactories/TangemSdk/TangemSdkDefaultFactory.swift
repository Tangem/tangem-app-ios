//
//  TangemSdkDefaultFactory.swift
//  Tangem
//
//  Created by Alexander Osokin on 07.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class TangemSdkDefaultFactory {
    func makeTangemSdk(with config: Config) -> TangemSdk {
        let sdk = TangemSdk()
        sdk.config = config
        return sdk
    }
}

extension TangemSdkDefaultFactory: TangemSdkFactory {
    func makeTangemSdk() -> TangemSdk {
        let config = TangemSdkConfigFactory().makeDefaultConfig()
        return makeTangemSdk(with: config)
    }
}
