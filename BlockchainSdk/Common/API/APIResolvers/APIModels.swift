//
//  APIModels.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 04/04/24.
//  Copyright © 2024 Tangem AG. All rights reserved.

import Foundation

public typealias APIList = [String: [NetworkProviderType]]

public enum NetworkProviderType {
    case `public`(link: String)
    case nowNodes
    case quickNode
    case getBlock
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
    case dwellir
    case onfinality
    case koinos
    case clore
}

struct NodeInfo: HostProvider {
    let url: URL
    let headers: APIHeaderKeyInfo?

    var link: String { url.absoluteString }

    var host: String { link }

    init(url: URL, keyInfo: APIHeaderKeyInfo? = nil) {
        self.url = url
        headers = keyInfo
    }
}

struct APIHeaderKeyInfo {
    let headerName: String
    let headerValue: String
}
