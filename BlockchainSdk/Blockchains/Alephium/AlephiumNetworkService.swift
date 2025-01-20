//
//  AlephiumNetworkService.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 20.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// TODO: - https://tangem.atlassian.net/browse/IOS-8983
final class AlephiumNetworkService: MultiNetworkProvider {
    var providers: [AlephiumNetworkProvider] = []
    var currentProviderIndex: Int = 0
}
