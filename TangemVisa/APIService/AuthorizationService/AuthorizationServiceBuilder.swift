//
//  AuthorizationServiceBuilder.swift
//  TangemApp
//
//  Created by Andrew Son on 15.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Moya

struct AuthorizationServiceBuilder {
    func build(urlSessionConfiguration: URLSessionConfiguration) -> CommonVisaAuthorizationService {
        CommonVisaAuthorizationService(apiService: .init(
            provider: MoyaProviderBuilder().buildProvider(configuration: urlSessionConfiguration),
            logger: InternalLogger(),
            decoder: JSONDecoderFactory().makePayAPIDecoder()
        ))
    }
}
