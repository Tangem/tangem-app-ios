//
//  MultiNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 12/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Moya
import TangemLogger
import TangemNetworkUtils

@available(iOS 13.0, *)
protocol MultiNetworkProvider: AnyObject, HostProvider {
    associatedtype Provider: HostProvider

    var providers: [Provider] { get }
    var currentProviderIndex: Int { get set }
}

extension MultiNetworkProvider {
    var provider: Provider? {
        if currentProviderIndex >= providers.count {
            return nil
        }

        return providers[currentProviderIndex]
    }

    var host: String { provider?.host ?? .unknown }

    func providerPublisher<T>(for requestPublisher: @escaping (_ provider: Provider) -> AnyPublisher<T, Error>) -> AnyPublisher<T, Error> {
        guard let provider else {
            return .anyFail(error: BlockchainSdkError.noAPIInfo)
        }

        let currentHost = provider.host
        return requestPublisher(provider)
            .catch { [weak self] error -> AnyPublisher<T, Error> in
                guard let self = self else { return .anyFail(error: error) }

                if let moyaError = error as? MoyaError, case .statusCode(let resp) = moyaError {
                    NetworkLogger.error("Message: \(String(data: resp.data, encoding: .utf8) ?? "")", error: moyaError)
                } else {
                    NetworkLogger.error(error: error)
                }

                if case WalletError.noAccount = error {
                    return .anyFail(error: error)
                }

                if case WalletError.accountNotActivated = error {
                    return .anyFail(error: error)
                }

                let beforeSwitchIfNeededHost = host

                if let nextHost = switchProviderIfNeeded(for: currentHost) {
                    // Send event if api did switched by host value
                    if nextHost != beforeSwitchIfNeededHost {
                        NetworkLogger.info("Next host: \(nextHost)")

                        ExceptionHandler.shared.handleAPISwitch(
                            currentHost: currentHost,
                            nextHost: nextHost,
                            message: error.localizedDescription
                        )
                    }

                    return providerPublisher(for: requestPublisher)
                }

                // Need captured currentHost, to be able to get hosting after switching.
                let returnedError = MultiNetworkProviderError(networkError: error, lastRetryHost: currentHost)
                return .anyFail(error: returnedError)
            }
            .eraseToAnyPublisher()
    }

    // NOTE: There also copy of this behaviour in the wild, if you want to update something
    // in the code, don't forget to update also Solano.Swift framework, class NetworkingRouter
    private func switchProviderIfNeeded(for errorHost: String) -> String? {
        if errorHost != host { // Do not switch the provider, if it was switched already
            return providers[currentProviderIndex].host
        }

        currentProviderIndex += 1
        if currentProviderIndex < providers.count {
            return providers[currentProviderIndex].host
        }
        resetProviders()
        return nil
    }

    private func resetProviders() {
        currentProviderIndex = 0
    }
}

struct MultiNetworkProviderError: LocalizedError {
    let networkError: Error
    let lastRetryHost: String

    // MARK: - LocalizedError

    var errorDescription: String? {
        (networkError as? MoyaError)?.localizedDescription ?? defaultMoyaError.localizedDescription
    }

    var failureReason: String? {
        (networkError as? MoyaError)?.failureReason ?? defaultMoyaError.failureReason
    }

    var recoverySuggestion: String? {
        (networkError as? MoyaError)?.recoverySuggestion ?? defaultMoyaError.recoverySuggestion
    }

    var helpAnchor: String? {
        (networkError as? MoyaError)?.helpAnchor ?? defaultMoyaError.helpAnchor
    }

    private var defaultMoyaError: MoyaError {
        .underlying(networkError, nil)
    }
}
