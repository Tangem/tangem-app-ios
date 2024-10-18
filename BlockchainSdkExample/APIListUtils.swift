//
//  ConfigUtils.swift
//  BlockchainSdkExample
//
//  Created by Andrew Son on 27/04/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct ConfigUtils {
    private let providersFileName = "providers_order"
    private let configFileName = "config_dev"

    func parseProvidersJson() -> APIList {
        do {
            let apiListDTO = try readBundleFile(with: providersFileName, type: APIListDTO.self)
            return convertToSDKModels(apiListDTO)
        } catch {
            return [:]
        }
    }

    func parseKeysJson() -> BlockchainSdkConfig {
        do {
            let keys = try readBundleFile(with: configFileName, type: Keys.self)
            var credentials: [BlockchainSdkConfig.GetBlockCredentials.Credential] = []

            Blockchain.allMainnetCases.forEach { blockchain in
                if let accessTokens = keys.getBlockAccessTokens[blockchain.codingKey] {
                    BlockchainSdkConfig.GetBlockCredentials.TypeValue.allCases.forEach { type in
                        if let token = accessTokens[type.rawValue] {
                            credentials.append(.init(blockchain: blockchain, type: type, key: token))
                        }
                    }
                }
            }
            return BlockchainSdkConfig(
                blockchairApiKeys: keys.blockchairApiKeys,
                blockcypherTokens: keys.blockcypherTokens,
                infuraProjectId: keys.infuraProjectId,
                nowNodesApiKey: keys.nowNodesApiKey,
                getBlockCredentials: .init(credentials: credentials),
                kaspaSecondaryApiUrl: keys.kaspaSecondaryApiUrl,
                tronGridApiKey: keys.tronGridApiKey,
                hederaArkhiaApiKey: keys.hederaArkhiaKey,
                polygonScanApiKey: keys.polygonScanApiKey,
                koinosProApiKey: keys.koinosProApiKey,
                tonCenterApiKeys: .init(mainnetApiKey: keys.tonCenterApiKey.mainnet, testnetApiKey: keys.tonCenterApiKey.testnet),
                fireAcademyApiKeys: .init(mainnetApiKey: keys.chiaFireAcademyApiKey, testnetApiKey: keys.chiaFireAcademyApiKey),
                chiaTangemApiKeys: .init(mainnetApiKey: keys.chiaTangemApiKey),
                quickNodeSolanaCredentials: .init(apiKey: keys.quiknodeApiKey, subdomain: keys.quiknodeSubdomain),
                quickNodeBscCredentials: .init(apiKey: keys.bscQuiknodeApiKey, subdomain: keys.bscQuiknodeSubdomain),
                defaultNetworkProviderConfiguration: .init(logger: .verbose, urlSessionConfiguration: .standard),
                networkProviderConfigurations: [:],
                bittensorDwellirKey: keys.bittensorDwellirKey,
                bittensorOnfinalityKey: keys.bittensorOnfinalityKey
            )
        } catch {
            return .init(
                blockchairApiKeys: [],
                blockcypherTokens: [],
                infuraProjectId: "",
                nowNodesApiKey: "",
                getBlockCredentials: .init(credentials: []),
                kaspaSecondaryApiUrl: nil,
                tronGridApiKey: "",
                hederaArkhiaApiKey: "",
                polygonScanApiKey: "",
                koinosProApiKey: "",
                tonCenterApiKeys: .init(mainnetApiKey: "", testnetApiKey: ""),
                fireAcademyApiKeys: .init(mainnetApiKey: "", testnetApiKey: ""),
                chiaTangemApiKeys: .init(mainnetApiKey: ""),
                quickNodeSolanaCredentials: .init(apiKey: "", subdomain: ""),
                quickNodeBscCredentials: .init(apiKey: "", subdomain: ""),
                defaultNetworkProviderConfiguration: .init(logger: .verbose),
                bittensorDwellirKey: "",
                bittensorOnfinalityKey: ""
            )
        }
    }

    private func convertToSDKModels(_ listDTO: APIListDTO) -> APIList {
        return listDTO.reduce(into: [:]) { partialResult, element in
            let providers: [NetworkProviderType] = element.value.compactMap { apiInfo in
                switch APIType(rawValue: apiInfo.type) {
                case .public:
                    guard
                        let link = apiInfo.url,
                        // Check that link is valid
                        URL(string: link) != nil
                    else {
                        return nil
                    }

                    return NetworkProviderType.public(link: link)
                case .private:
                    return mapToNetworkProviderType(name: apiInfo.name)
                case .none:
                    return nil
                }
            }

            partialResult[element.key] = providers
        }
    }

    private func readBundleFile<T: Decodable>(with name: String, type: T.Type) throws -> T {
        guard let path = Bundle.main.url(forResource: name, withExtension: "json") else {
            throw NSError(domain: "Failed to find json file with name: \"\(name)\"", code: -9999, userInfo: nil)
        }

        return try JSONDecoder().decode(type, from: Data(contentsOf: path))
    }

    private func mapToNetworkProviderType(name: String?) -> NetworkProviderType? {
        guard
            let name,
            let apiProvider = APIProvider(rawValue: name)
        else {
            return nil
        }

        return apiProvider.blockchainProvider
    }
}

typealias APIListDTO = [String: [APIInfoDTO]]

struct APIInfoDTO: Decodable {
    let type: String
    let name: String?
    let url: String?
}

enum APIType: String {
    case `private`
    case `public`
}

enum APIProvider: String {
    case nownodes
    case quicknode
    case getblock
    case blockchair
    case blockcypher
    case ton
    case tron
    case arkhiaHedera
    case infura
    case adalite
    case tangemRosetta
    case fireAcademy
    case tangemChia
    case solana
    case kaspa
    case koinos

    var blockchainProvider: NetworkProviderType {
        switch self {
        case .nownodes: return .nowNodes
        case .quicknode: return .quickNode
        case .getblock: return .getBlock
        case .blockchair: return .blockchair
        case .blockcypher: return .blockcypher
        case .ton: return .ton
        case .tron: return .tron
        case .arkhiaHedera: return .arkhiaHedera
        case .infura: return .infura
        case .adalite: return .adalite
        case .tangemRosetta: return .tangemRosetta
        case .fireAcademy: return .fireAcademy
        case .tangemChia: return .tangemChia
        case .solana: return .solana
        case .kaspa: return .kaspa
        case .koinos: return .koinos
        }
    }
}

struct Keys: Decodable {
    let blockchairApiKeys: [String]
    let blockcypherTokens: [String]
    let infuraProjectId: String
    let nowNodesApiKey: String
    let getBlockApiKey: String
    let getBlockAccessTokens: [String: [String: String]]
    let kaspaSecondaryApiUrl: String
    let tonCenterApiKey: TonCenterApiKeys
    let chiaFireAcademyApiKey: String
    let chiaTangemApiKey: String
    let tronGridApiKey: String
    let hederaArkhiaKey: String
    let quiknodeApiKey: String
    let quiknodeSubdomain: String
    let bscQuiknodeApiKey: String
    let bscQuiknodeSubdomain: String
    let polygonScanApiKey: String
    let koinosProApiKey: String
    let bittensorDwellirKey: String
    let bittensorOnfinalityKey: String
}

struct TonCenterApiKeys: Decodable {
    let mainnet: String
    let testnet: String
}
