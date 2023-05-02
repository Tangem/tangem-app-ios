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
    let tokens: [Token]

    private let version: Int
    private let group: String?
    private let sort: String?

    init(
        tokens: [UserTokenList.Token],
        version: Int = 0,
        group: String = GroupType.none.rawValue,
        sort: String = SortType.manual.rawValue
    ) {
        self.tokens = tokens
        self.version = version
        self.group = group
        self.sort = sort
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
        let exchangeable: Bool?
        let contractAddress: String?
    }

    enum GroupType: String, Codable {
        case none
    }

    enum SortType: String, Codable {
        case manual
    }
}
