//
//  NetworkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 25.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

class NetworkProvider<Target: TargetType>: MoyaProvider<Target> {
    init(configuration: NetworkProviderConfiguration = NetworkProviderConfiguration()) {
        let session = Session(configuration: configuration.urlSessionConfiguration)

        super.init(session: session, plugins: configuration.plugins)
    }
}
