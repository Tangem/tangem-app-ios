//
//  VisaAPIServiceBuilder.swift
//  TangemVisa
//
//  Created by Andrew Son on 24/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

public struct VisaAPIServiceBuilder {
    public init() {}

    public func build(isTestnet: Bool, urlSessionConfiguration: URLSessionConfiguration, logger: VisaLogger) -> VisaAPIService {
        let logger = InternalLogger(logger: logger)
        let provider = MoyaProvider<VisaAPITarget>(session: Session(configuration: urlSessionConfiguration))

        return CommonVisaAPIService(isTestnet: isTestnet, provider: provider, logger: logger)
    }
}
