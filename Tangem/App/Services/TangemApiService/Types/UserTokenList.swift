//
//  UserTokenList.swift
//  Tangem
//
//  Created by Sergey Balashov on 15.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemSdk.DerivationPath

/// The API model for the`user-tokens/:key/` routing
struct UserTokenList: Codable {
    var tokens: [Token]
    var group: GroupType
    var sort: SortType

    private let version: Int

    init(
        tokens: [Token],
        group: GroupType,
        sort: SortType,
        version: Int
    ) {
        self.tokens = tokens
        self.group = group
        self.sort = sort
        self.version = version
    }
}

extension UserTokenList {
    static var initialVersion: Int { 0 }

    static var empty: Self {
        return Self(tokens: [], group: .none, sort: .manual)
    }

    init(
        tokens: [Token],
        group: GroupType,
        sort: SortType
    ) {
        self.init(
            tokens: tokens,
            group: group,
            sort: sort,
            version: Self.initialVersion
        )
    }
}

extension UserTokenList {
    struct Token: Codable, Hashable {
        let id: String?
        let networkId: String
        let name: String
        let symbol: String
        let decimals: Int
        let derivationPath: DerivationPath?
        let contractAddress: String?
    }

    enum GroupType: String, Codable {
        case none
        case network
    }

    enum SortType: String, Codable {
        case manual
        case balance
    }
}
