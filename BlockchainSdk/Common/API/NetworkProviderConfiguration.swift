//
//  NetworkProviderConfiguration.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 25.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemSdk
import TangemNetworkUtils

public struct NetworkProviderConfiguration {
    let logOptions: TangemNetworkLoggerPlugin.LogOptions?
    let urlSessionConfiguration: URLSessionConfiguration
    let credentials: Credentials?

    public init(
        logOptions: TangemNetworkLoggerPlugin.LogOptions? = .default,
        urlSessionConfiguration: URLSessionConfiguration = .standard,
        credentials: Credentials? = nil
    ) {
        self.logOptions = logOptions
        self.urlSessionConfiguration = urlSessionConfiguration
        self.credentials = credentials
    }

    var plugins: [PluginType] {
        var plugins: [PluginType] = []

        if let logOptions = logOptions {
            plugins.append(TangemNetworkLoggerPlugin(logOptions: logOptions))
        }

        if let credentials {
            plugins.append(CredentialsPlugin { _ -> URLCredential? in
                .init(
                    user: credentials.user,
                    password: credentials.password,
                    persistence: .none
                )
            })
        }

        return plugins
    }
}

public extension URLSessionConfiguration {
    static let standard: URLSessionConfiguration = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 30
        return configuration
    }()
}
