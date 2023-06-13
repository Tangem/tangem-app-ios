//
//  CoinsRequestModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 24.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct CoinsListRequestModel: Encodable {
    let contractAddress: String?
    let networkIds: String?
    let searchText: String?
    let exchangeable: Bool?
    let limit: Int?
    let offset: Int?
    let active: Bool?
    /// Token or coin id
    let ids: String?

    init(
        contractAddress: String? = nil,
        networkIds: [String],
        searchText: String? = nil,
        exchangeable: Bool? = nil,
        limit: Int? = nil,
        offset: Int? = nil,
        active: Bool? = nil,
        ids: [String] = []
    ) {
        self.contractAddress = contractAddress
        self.networkIds = networkIds.isEmpty ? nil : networkIds.joined(separator: ",")
        self.searchText = searchText == "" ? nil : searchText
        self.exchangeable = exchangeable
        self.limit = limit
        self.offset = offset
        self.active = active
        self.ids = ids.isEmpty ? nil : ids.joined(separator: ",")
    }
}
