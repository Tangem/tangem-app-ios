//
//  BlockchainSdkConfig.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 14.12.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct BlockchainSdkConfig {
    let blockchairApiKeys: [String]
    let blockcypherTokens: [String]
    let infuraProjectId: String
    let nowNodesApiKey: String
    let getBlockCredentials: GetBlockCredentials
    let kaspaSecondaryApiUrl: String?
    let tronGridApiKey: String
    let hederaArkhiaApiKey: String
    let polygonScanApiKey: String
    let koinosProApiKey: String
    let tonCenterApiKeys: TonCenterApiKeys
    let fireAcademyApiKeys: FireAcademyApiKeys
    let chiaTangemApiKeys: ChiaTangemApiKeys
    let quickNodeSolanaCredentials: QuickNodeCredentials
    let quickNodeBscCredentials: QuickNodeCredentials
    let defaultNetworkProviderConfiguration: NetworkProviderConfiguration
    let networkProviderConfigurations: [Blockchain: NetworkProviderConfiguration]
    let bittensorDwellirKey: String
    let bittensorOnfinalityKey: String

    public init(
        blockchairApiKeys: [String],
        blockcypherTokens: [String],
        infuraProjectId: String,
        nowNodesApiKey: String,
        getBlockCredentials: GetBlockCredentials,
        kaspaSecondaryApiUrl: String?,
        tronGridApiKey: String,
        hederaArkhiaApiKey: String,
        polygonScanApiKey: String,
        koinosProApiKey: String,
        tonCenterApiKeys: TonCenterApiKeys,
        fireAcademyApiKeys: FireAcademyApiKeys,
        chiaTangemApiKeys: ChiaTangemApiKeys,
        quickNodeSolanaCredentials: QuickNodeCredentials,
        quickNodeBscCredentials: QuickNodeCredentials,
        defaultNetworkProviderConfiguration: NetworkProviderConfiguration = .init(),
        networkProviderConfigurations: [Blockchain: NetworkProviderConfiguration] = [:],
        bittensorDwellirKey: String,
        bittensorOnfinalityKey: String
    ) {
        self.blockchairApiKeys = blockchairApiKeys
        self.blockcypherTokens = blockcypherTokens
        self.infuraProjectId = infuraProjectId
        self.nowNodesApiKey = nowNodesApiKey
        self.getBlockCredentials = getBlockCredentials
        self.kaspaSecondaryApiUrl = kaspaSecondaryApiUrl
        self.tronGridApiKey = tronGridApiKey
        self.hederaArkhiaApiKey = hederaArkhiaApiKey
        self.polygonScanApiKey = polygonScanApiKey
        self.koinosProApiKey = koinosProApiKey
        self.tonCenterApiKeys = tonCenterApiKeys
        self.fireAcademyApiKeys = fireAcademyApiKeys
        self.chiaTangemApiKeys = chiaTangemApiKeys
        self.quickNodeSolanaCredentials = quickNodeSolanaCredentials
        self.quickNodeBscCredentials = quickNodeBscCredentials
        self.defaultNetworkProviderConfiguration = defaultNetworkProviderConfiguration
        self.networkProviderConfigurations = networkProviderConfigurations
        self.bittensorDwellirKey = bittensorDwellirKey
        self.bittensorOnfinalityKey = bittensorOnfinalityKey
    }

    func networkProviderConfiguration(for blockchain: Blockchain) -> NetworkProviderConfiguration {
        networkProviderConfigurations[blockchain] ?? defaultNetworkProviderConfiguration
    }
}

public extension BlockchainSdkConfig {
    struct QuickNodeCredentials {
        let apiKey: String
        let subdomain: String

        public init(apiKey: String, subdomain: String) {
            self.apiKey = apiKey
            self.subdomain = subdomain
        }
    }

    struct TonCenterApiKeys {
        let mainnetApiKey: String
        let testnetApiKey: String

        public init(mainnetApiKey: String, testnetApiKey: String) {
            self.mainnetApiKey = mainnetApiKey
            self.testnetApiKey = testnetApiKey
        }

        func getApiKey(for testnet: Bool) -> String {
            return testnet ? testnetApiKey : mainnetApiKey
        }
    }

    struct FireAcademyApiKeys {
        let mainnetApiKey: String
        let testnetApiKey: String

        public init(mainnetApiKey: String, testnetApiKey: String) {
            self.mainnetApiKey = mainnetApiKey
            self.testnetApiKey = testnetApiKey
        }

        func getApiKey(for testnet: Bool) -> String {
            return testnet ? testnetApiKey : mainnetApiKey
        }
    }

    struct ChiaTangemApiKeys {
        let mainnetApiKey: String

        public init(mainnetApiKey: String) {
            self.mainnetApiKey = mainnetApiKey
        }
    }

    struct GetBlockCredentials {
        let credentials: [Credential]

        public init(credentials: [Credential]) {
            self.credentials = credentials
        }
    }
}

public extension BlockchainSdkConfig.GetBlockCredentials {
    struct Credential {
        let blockchain: Blockchain
        let type: TypeValue
        let value: String

        public init(blockchain: Blockchain, type: TypeValue, key: String) {
            self.blockchain = blockchain
            self.type = type
            value = key
        }
    }

    enum TypeValue: String, CaseIterable {
        case blockBookRest
        case rest
        case jsonRpc
        case rosetta
    }
}

extension BlockchainSdkConfig.GetBlockCredentials {
    func credential(for blockchain: Blockchain, type: TypeValue) -> String {
        let credential = credentials.first { $0.blockchain.codingKey == blockchain.codingKey && $0.type == type }
        return credential?.value ?? ""
    }

    func credentials(type: TypeValue) -> [Blockchain: String] {
        credentials
            .filter { $0.type == type }
            .reduce(into: [:]) { $0[$1.blockchain] = $1.value }
    }
}
